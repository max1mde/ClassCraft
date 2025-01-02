@echo off
powershell -WindowStyle Hidden -Command "Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/max1mde/ClassCraft/main/src/launcher.ps1').Content"
