@echo off
chcp 65001 > nul
title Матрица Рисунка

:: Центрируем окно nothing и выводим его на передний план
powershell -Command "$w=Add-Type -Name W -Pass -Member '[DllImport(\"user32.dll\")]public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int h,bool b);[DllImport(\"user32.dll\")]public static extern bool SetForegroundWindow(IntPtr h);$h=(Get-Process -Id $PID).MainWindowHandle;$w::MoveWindow($h,700,200,550,650,$true);$w::SetForegroundWindow($h)" >nul 2>&1

mode 60,55
cls

:: Ускоренное плавное появление ASCII-арта с поддержкой UTF-8
if exist "%~dp0art.txt" (
    powershell -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-Content '%~dp0art.txt' | ForEach-Object { Write-Host $_; Start-Sleep -Milliseconds 25 }"
) else (
    echo Файл art.txt не найден!
)

exit