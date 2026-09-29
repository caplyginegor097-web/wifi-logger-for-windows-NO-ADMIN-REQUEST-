@echo off
:: Настройка UTF-8 для корректного лога и анимации
chcp 65001 > nul
title Сетевой Аудит (Бронированная Версия)

:: Сдвигаем окно аудита влево-вверх, чтобы окна не наслаивались
powershell -Command "$w=Add-Type -Name W -Pass -Member '[DllImport(\"user32.dll\")]public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int h,bool b);';$w::MoveWindow((Get-Process -Id $PID).MainWindowHandle,50,50,750,600,$true)" >nul 2>&1

:: Сбор сырых данных сети во временные файлы
netsh wlan show interfaces > "%temp%\wlan_raw.txt" 2>nul
findstr /i "SSID" "%temp%\wlan_raw.txt" | findstr /v /i "BSSID" > "%temp%\wlan_ssid.txt"
findstr /i "Signal Сигнал" "%temp%\wlan_raw.txt" > "%temp%\wlan_signal.txt"
findstr /i "Authentication Аутентификация" "%temp%\wlan_raw.txt" > "%temp%\wlan_auth.txt"

set "ssid_name="
for /f "tokens=2 delims=:" %%a in ('type "%temp%\wlan_ssid.txt" 2^>nul') do set "ssid_name=%%a"

if not "%ssid_name%"=="" (
    setlocal enabledelayedexpansion
    set "trimmed_ssid=!ssid_name:~1!"
    netsh wlan show profile name="!trimmed_ssid!" key=clear > "%temp%\wlan_prof.txt" 2>nul
    endlocal
)
findstr /i "Content Ключ Содерж" "%temp%\wlan_prof.txt" > "%temp%\wlan_pass.txt" 2>nul

:: Формирование финального файла отчета
set "reportfile=%temp%\wlan_final.txt"
echo =================================================== > "%reportfile%"
echo   РЕЗУЛЬТАТЫ СЕТЕВОГО АУДИТА [%computername%] >> "%reportfile%"
echo =================================================== >> "%reportfile%"
echo 1. Имя Wi-Fi сети (SSID)    : >> "%reportfile%"
type "%temp%\wlan_ssid.txt" >> "%reportfile%" 2>nul
if errorlevel 1 echo      [Не подключено или Wi-Fi выключен] >> "%reportfile%"
echo 2. Пароль (Key Content)     : >> "%reportfile%"
type "%temp%\wlan_pass.txt" >> "%reportfile%" 2>nul
if errorlevel 1 echo      [Не найдено / Открытая сеть] >> "%reportfile%"
echo 3. Протокол безопасности     : >> "%reportfile%"
type "%temp%\wlan_auth.txt" >> "%reportfile%" 2>nul
echo 4. Уровень сигнала (Signal) : >> "%reportfile%"
type "%temp%\wlan_signal.txt" >> "%reportfile%" 2>nul
echo =================================================== >> "%reportfile%"
echo 5. Устройства в локальной сети (ARP таблица): >> "%reportfile%"
echo. >> "%reportfile%"
arp -a >> "%reportfile%" 2>nul
echo =================================================== >> "%reportfile%"

:: Сохраняем лог на флешку
set "logfile=%~dp0wifi_%computername%_log.txt"
type "%reportfile%" > "%logfile%"

:: Подчищаем временные файлы
del "%temp%\wlan_*.txt" > nul 2>&1

cls
:: ЗАПУСК NOTHING ПОВЕРХ ВСЕХ ОКН (с минимальной задержкой)
if exist "%~dp0nothing.bat" (
    timeout /t 1 /nobreak >nul
    start "" cmd /c "call "%~dp0nothing.bat""
)

:: Ускоренный построчный вывод с фиксом русской кодировки (всё займет ~2 сек)
powershell -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-Content '%logfile%' | ForEach-Object { Write-Host $_; Start-Sleep -Milliseconds 35 }"

echo.
echo [ГОТОВО] Лог успешно сохранен на флешку!
echo Файл: wifi_%computername%_log.txt
echo.
pause

