@Echo off & title Capture Wim v5

::----------------------------------------------
:: DM ToolKit v5.0 / Capture wim v5
:: Copyright (c) 2025 DM. All rights reserved.
::----------------------------------------------
fsutil dirty query %systemdrive% >nul 2>&1 || (powershell -Command "Start-Process '%~f0' -Verb RunAs" & exit /b)

setlocal EnableExtensions EnableDelayedExpansion

set "A=-----------------"
set "B=------------------"
set "C=------------"
set "E=----------------"
set "F=---------------"
set "L=%F%%F%%F%%F%"

set "Bin=%~dp0Bin"
set "EL=if errorlevel"

set "log=%~dp0Debug.log"
set "Dism=%Bin%\Dism\Dism.exe"
set "Oscdimg=%Bin%\oscdimg.exe"
set "Wimlib=%Bin%\Wimlib\wimlib-imagex.exe"

set "W=Windows"
set "M=Microsoft"
set "OS11=%W% 11"
set "OS10=%W% 10"

set "CW=CaptureWim"
set "Wim=install.wim"
set "TS=TEMP_SOFTWARE"

set "_Wim=%~dp0WIM"
set "D11=%_Wim%\%W%_11"
set "D10=%_Wim%\%W%_10"
set "WF11=%D11%\%Wim%"
set "WF10=%D10%\%Wim%"

set "ISO=%~dp0ISO"
set "ISO11=%ISO%\ISO11"
set "ISO10=%ISO%\ISO10"
set "_MKISO=%~dp0MKISO"

set "INI=%~dp0Config.ini"
set "Exclu=%Bin%\Exclu.ini"

set "W11=DM 11 Professional"
set "W10=DM 10 Professional"

set "CH=%_MKISO%\*.iso"
set "ISO11X=%ISO11%\sources\%Wim%"
set "ISO10X=%ISO10%\sources\%Wim%"

set "BIOSBoot=boot\etfsboot.com"
set "UEFIBoot=efi\microsoft\boot\efisys_noprompt.bin"

set "Option=RemoveAll RemoveWim RemoveISO RemovePost AutoExit PreAuto NoWim _DebugAuto _DebugManual"

for %%# in (%Option% MkISO Threads Cmp Auto1 Auto2) do call :ReadINI %%#
for %%1 in (%Option% MkISO) do if "%%1"=="" set "%%1=0"
if "%RemoveAll%"=="1" set "RemoveWim=1" & set "RemoveISO=1"
if "%RemoveISO%"=="1" if exist "%CH%" del /f /q "%CH%"
if "%RemoveWim%"=="1" for %%1 in ("%WF11%" "%WF10%" "%ISO11X%" "%ISO10X%") do if exist %%1 del /f /q %%1
if "%PreAuto%"=="1" for %%1 in (%Option% MkISO Threads Cmp Auto1 Auto2) do call :ReadINI %%1 & call :WinAuto
if "%_DebugAuto%"=="1" call :Debug "Auto" "WinAuto"
if "%_DebugManual%"=="1" call :Debug "Manual" "WinManual"
for %%1 in ("%WF11%" "%WF10%") do if exist %%1 (
	if "%PreAuto%"=="0" if "%MkISO%"=="1" (goto :ISO) else goto :Menu
)

::----------------------------------------------
:Menu
cls
set "found=0"
set "Num=3"

for %%1 in ("%WF11%" "%WF10%") do if not exist %%1 mode con cols=62 lines=14
for %%1 in ("%WF11%" "%WF10%" "%ISO11X%" "%ISO10X%") do if exist %%1 (
	mode con cols=62 lines=18
	set "found=1"
	set "Num=5"
)
call :DisplayOS1 "%E%" "%CW%" "MainMenu"
Echo.
Echo                         [1] Simple
Echo.
Echo                         [2] Double
Echo.
if "%found%"=="1" (
	Echo                         [3] Information
	Echo.
	Echo                         [4] ISO
	Echo.
)
Echo                         [%Num%] Reboot
Echo.
Echo                         [X] Quitter
Echo.
Echo %L%
choice /C 12345X /N /M ">> Option : "
%EL% 6 Exit
if "%found%"=="1" (
	%EL% 5 goto :Setup
	%EL% 4 goto :ISO
	%EL% 3 goto :Info
)
if "%found%"=="0" (%EL% 3 goto :Setup)
%EL% 2 goto :Auto
%EL% 1 goto :Manual

::----------------------------------------------
:Manual
cls
mode con cols=62 lines=10
call :DisplayOS1 "%A%" "%CW%" "Manual"
Echo.
set /p Manual="| Drive : "
if "%Manual%"=="X" goto :Menu
Echo.
if not defined Cmp (
	choice /C 12X /N /M "| FAST / LZX [1/2/3] : "
	%EL% 3 goto :Menu
	%EL% 2 (set "Cmp=LZX" & goto :WinManual)
	%EL% 1 (set "Cmp=FAST" & goto :WinManual)
) else goto :WinManual

::----------------------------------------------
:Auto
cls
mode con cols=62 lines=12
call :DisplayOS1 "%B%" "%CW%" "Auto"
Echo.
set /p Auto1="| %OS11% Drive : "
if "%Auto1%"=="X" goto :Menu
Echo.
set /p Auto2="| %OS10% Drive : "
if "%Auto2%"=="X" goto :Menu
Echo.
if not defined Cmp (
	choice /C 12 /N /M "| FAST / LZX [1/2] : "
	%EL% 2 (set "Cmp=LZX" & goto :WinAuto)
	%EL% 1 (set "Cmp=FAST" & goto :WinAuto)
) else goto :WinAuto

::----------------------------------------------
:WinManual
set WinManual=1
if "%_DebugManual%"=="1" set "Manual=J"
call :HostInfo "%Manual%" >nul 2>&1
if "%_DebugManual%"=="0" cls & mode con cols=62 lines=28
if "%HostBuild%" geq "22631" (
	set "H11=1"
	if exist "%WF11%" del /f /q "%WF11%"
	call :Menuimage "%Manual%" "%OS11%" "%WF11%" "%W11%"
)
if "%HostBuild%" equ "19045" (
	set "H10=1"
	if exist "%WF10%" del /f /q "%WF10%"
	call :Menuimage "%Manual%" "%OS10%" "%WF10%" "%W10%"
)
if "%RemovePost%"=="1" call :Clean "%Manual%"
if "%MkISO%"=="1" call :ISO
for %%1 in ("%_DebugManual%" "%AutoExit%") do if %%1=="1" exit
if "%AutoExit%"=="0" call :End

::----------------------------------------------
:WinAuto
if "%PreAuto%"=="0" (set "WinAuto=1") else set "WinAuto=2"
if "%_DebugAuto%"=="0" cls & mode con cols=62 lines=28
for %%1 in ("%WF11%" "%WF10%") do if exist %%1 del /f /q %%1
call :Menuimage "%Auto1%" "%OS11%" "%WF11%" "%W11%"
if "%RemovePost%"=="1" call :Clean "%Auto1%"
if "%_DebugAuto%"=="0" cls & mode con cols=62 lines=28
call :Menuimage "%Auto2%" "%OS10%" "%WF10%" "%W10%"
if "%RemovePost%"=="1" call :Clean "%Auto2%"
if "%MkISO%"=="1" call :ISO
for %%1 in ("%_DebugAuto%" "%AutoExit%" "%PreAuto%") do if %%1=="1" exit
if "%AutoExit%"=="0" call :End

::----------------------------------------------
:ISO
setlocal EnableExtensions EnableDelayedExpansion
call :Setimg
for %%1 in ("%D11%" "%D10%") do if exist %%1 (set "WinAuto=2")
if "%H11%"=="1" goto :I11
if "%H10%"=="1" goto :I10
:I11
for %%1 in ("%ISO11X%" "%WF11%") do if exist %%1 (
	call :GetImageIndexInfo %%1
	call :Find "%_MKISO%\DM_11" "%_MKISO%\%W%_11"
	call :ISOs "%WF11%" "%ISO11%" "!DM!" "ISO 11"
	call :MV "%ISO11X%" "%D11%"
	if "%WinAuto%"=="2" (goto :I10) else goto :Iss
)
:I10
for %%1 in ("%ISO10X%" "%WF10%") do if exist %%1 (
	call :GetImageIndexInfo %%1
	call :Find "%_MKISO%\DM_10" "%_MKISO%\%W%_10"
	call :ISOs "%WF10%" "%ISO10%" "!DM!" "ISO 10"
	call :MV "%ISO10X%" "%D10%" & goto :Iss
)
:Iss
if "%NoWim%"=="1" for %%1 in ("%WF11%" "%WF10%") do if exist %%1 (del /f /q %%1)
if "%AutoExit%"=="1" (exit) else call :End
for %%1 in ("%WinManual%" "%WinAuto%") do if %%1=="1" call :End
goto :eof

:ISOs
for %%1 in ("%_DebugAuto%" "%_DebugManual%") do if %%1=="0" cls & mode con cols=62 lines=32
call :DisplayOS1 "%A%" "%CW%" "%~4"
if exist "%~1" call :MV "%~1" "%~2\sources"
call :OSC "%~2\%BIOSBoot%" "%~2\%UEFIBoot%" "%~2" "%~3_%ImageBuild%.%ImageServicePackBuild%_%ImageArchitecture%_%ImageDefaultLanguage%.iso"
goto :eof

:Find
(Echo.%ImageName% | findstr /C:"Professional" >nul && set "DM=%~1") || (Echo.%ImageName% | findstr /C:"Professionnel" >nul && set "DM=%~2")
goto :eof

::----------------------------------------------
:Info
call :Setimg
set "INF1=0"
set "INF2=0"

for %%1 in ("%WF11%" "%WF10%") do if exist %%1 set "INF1=1"
for %%1 in ("%ISO11X%" "%ISO10X%") do if exist %%1 set "INF2=1"
if "%INF1%"=="1" call :Info1 "%WF11%" "%WF10%"
if "%INF2%"=="1" call :Info1 "%ISO11X%" "%ISO10X%"
call :Setimg
pause & goto :Menu

:Info1
cls
for %%1 in ("%~1" "%~2") do if exist %%1 mode con cols=62 lines=20
if exist "%~1" (if not exist "%~2" mode con cols=62 lines=11 & call :GetImageIndexInfo "%~1" & call :MenuInfo)
if exist "%~2" (if not exist "%~1" mode con cols=62 lines=11 & call :GetImageIndexInfo "%~2" & call :MenuInfo)
goto :eof

::----------------------------------------------
:MenuInfo
set Echo1=
set Echo2=

Echo.
(Echo.%ImageName% | findstr /C:"Professional" >nul && Echo %B% [ %ImageName% ] %B%) || (Echo.%ImageName% | findstr /C:"Professionnel" >nul && Echo %F% [ %ImageName% ] %F%)
Echo.
for %%1 in ("%WF11%" "%WF10%") do if exist %%1 set "Echo1=1"
for %%1 in ("%ISO11X%" "%ISO10X%") do if exist %%1 set "Echo2=1"
if "%Echo1%"=="1" Echo            Folder                   : WIM
if "%Echo2%"=="1" Echo            Folder                   : ISO
Echo			Image Build              : %ImageBuild%.%ImageServicePackBuild%
Echo			Image Architecture       : %ImageArchitecture%
Echo			Image Default Language   : %ImageDefaultLanguage%
Echo.
Echo %L%
goto :eof

::----------------------------------------------
:: Full Environment
::----------------------------------------------
:MV
move /y "%~1" "%~2" >nul 2>&1
goto :eof

::----------------------------------------------
:DisplayOS1
Echo.
Echo %~1 [ %~2 ^|^| %~3 ] %~1
goto :eof

::----------------------------------------------
:DisplayOS2
Echo.
Echo %C% [ %CW% ^| %~1 ^| %~2 ] %C%
goto :eof

::----------------------------------------------
:Debug
for %%# in (%Option% Cmp Auto1 Auto2 Threads) do call :ReadINI %%#
call :Message "%~1"
@call :%~2 > %log% 2>&1
goto :eof

::----------------------------------------------
:End
Echo.
Echo %L%
pause & goto :Menu

::----------------------------------------------
:OSC
%Oscdimg% -bootdata:2#p0,e,b"%~1"#pEF,e,b"%~2" -o -h -m -u2 -udfver102 "%~3" "%~4"
goto :eof

::----------------------------------------------
:ReadINI
findstr /b /i %1 %INI% 1>nul && for /f "tokens=2 delims==" %%# in ('findstr /b /i %1 %INI%') do set "%1=%%#"
goto :eof

::----------------------------------------------
:CaptureLib
Echo.
%Wimlib% capture %2: %1 %3 %3 --image-property DISPLAYNAME=%3 --image-property DISPLAYDESCRIPTION=%3 --flags=Professional --config=%Exclu% --compress=%Cmp% --threads=%Threads%
goto :eof

::----------------------------------------------
:Setimg
set "ImageName="
set "ImageVersion="
set "ImageServicePackBuild="
set "ImageArchitecture="
set "ImageDefaultLanguage="
goto :eof

::----------------------------------------------
:Menuimage
call :Portable "%~1"
if "%Cmp%"=="LZX" call :DisplayOS2 "%~2" "LZX*" & goto :AFT
call :DisplayOS2 "%~2" "%Cmp%"
:AFT
for %%1 in ("FAST" "LZX") do if "%Cmp%"==%%1 call :CaptureLib "%~3" "%~1" "%~4"
goto :eof

::----------------------------------------------
:Message
mode con cols=62 lines=12
title Debug %~1
Echo.
Echo Running in Debug Mode %~1...
Echo.
Echo Writing debug log to: "Debug_%~1.log"
Echo.
@Echo on
@prompt $G & goto :eof

::----------------------------------------------
:Portable
for %%1 in ($WinREAgent\Scratch $WinREAgent\Backup) do if exist "%~1:\%%1" (del /f /q "%~1:\%%1") >nul 2>&1
set "K=HKLM\TEMP_SYSTEM\CurrentControlSet\Control"
set "V=PortableOperatingSystem"

Reg load HKLM\TEMP_SYSTEM "%~1:\%W%\System32\config\SYSTEM" >nul 2>&1
Reg query "%K%" /v "%V%" >nul 2>&1
%EL%==0 Reg delete "%K%" /v "%V%" /f >nul 2>&1
Reg unload HKLM\TEMP_SYSTEM >nul 2>&1
goto :eof

::----------------------------------------------
:Clean
set "Reg=HKLM\%TS%\%M%\%W%\CurrentVersion\RunOnceEx"
set "App=HKLM\%TS%\%M%\%W% NT\CurrentVersion\AppCompatFlags"
set "DM1=%W%\Setup\DM1"
set "DM2=%W%\Setup\DM2"

Reg load HKLM\%TS% "%~1:\%W%\System32\config\SOFTWARE" >nul 2>&1
Reg delete "%Reg%" /v "Title" /f >nul 2>&1
for %%V in ("Cleanup1" "Cleanup2") do Reg delete "%Reg%\DM" /v "%%~V" /f >nul 2>&1
Reg delete "%Reg%\DM" /ve /f >nul 2>&1
for %%K in ("%Reg%\DM" "%Reg%") do Reg delete "%%~K" /f >nul 2>&1
for %%K in (
	"%App%\CompatMarkers"
	"%App%\Shared"
	"%App%\TargetVersionUpgradeExperienceIndicators"
	"%App%\HwReqChk"
) do Reg delete "%%~K" /f >nul 2>&1
for %%D in ("%~1:\%DM1%" "%~1:\%DM2%") do rd /s /q "%%~D" >nul 2>&1
del /f /q "%~1:\Users\User\Desktop\Data Maniac.lnk" >nul 2>&1
Reg unload HKLM\%TS% >nul 2>&1
goto :eof

::----------------------------------------------
:GetImageIndexInfo
for /f "tokens=2 delims=:" %%a in ('%Dism% /Get-ImageInfo /ImageFile:"%~1" /Index:1 ^| findstr /i Name') do (set ImageName=%%a)
for /f "tokens=2 delims=: " %%b in ('%Dism% /Get-ImageInfo /ImageFile:"%~1" /Index:1 ^| findstr /i Architecture') do (set ImageArchitecture=%%b)
for /f "tokens=2 delims=: " %%c in ('%Dism% /Get-ImageInfo /ImageFile:"%~1" /Index:1 ^| findstr /i Version') do (set ImageVersion=%%c)
for /f "tokens=2 delims=:" %%d in ('%Dism% /Get-ImageInfo /ImageFile:"%~1" /Index:1 ^| find "ServicePack Build"') do (set ImageServicePackBuild=%%d)
for /f "tokens=1 delims= " %%e in ('%Dism% /Get-ImageInfo /ImageFile:"%~1" /Index:1 ^| findstr /i "Default"') do (set ImageDefaultLanguage=%%e)
if "%ImageVersion%" neq "10.0" if "%ImageVersion:~0,-6%" neq "11.0" set /A ImageBuild=%ImageVersion:~5,5%
set "ImageServicePackBuild=%ImageServicePackBuild:~1%"
set "ImageDefaultLanguage=%ImageDefaultLanguage:~1%"
set "ImageName=%ImageName:~1%"
goto :eof

::----------------------------------------------
:HostInfo
set "HKLM=HKLM\%TS%\%M%\%W% NT\CurrentVersion"
Reg Load HKLM\%TS% "%~1:\%W%\System32\config\SOFTWARE" >nul 2>&1
if exist "%~1:\%W%\SysWOW64" (set "HostArchitecture=x64") else set "HostArchitecture=x86"
for /f "tokens=3 delims= " %%i in ('Reg query "%HKLM%" /v "CurrentBuild" ^| find "REG_SZ"') do set HostBuild=%%i
for /f "tokens=3 delims= " %%j in ('Reg query "%HKLM%" /f "ReleaseId" ^| find "REG_SZ"') do (set /A HostReleaseVersion=%%j & if "%%j" lss "2004" set /A HostDisplayVersion=%%j)
if "%HostDisplayVersion%" equ "" for /f "tokens=3 delims= " %%k in ('Reg query "%HKLM%" /v "DisplayVersion" ^| find "REG_SZ"') do set "HostDisplayVersion=^(%%k^)"
for /f "tokens=3 delims= " %%l in ('Reg query "%HKLM%" /v "EditionID" ^| find "REG_SZ"') do set HostEdition=%%l
for /f "tokens=3 delims= " %%m in ('Reg query "%HKLM%" /v "InstallationType" ^| find "REG_SZ"') do set HostInstallationType=%%m
for /f "tokens=7 delims=[]. " %%r in ('ver 2^>nul') do set /A HostServicePackBuild=%%r
for /f "tokens=4-5 delims=[]. " %%s in ('ver 2^>nul') do (set "HostVersion=%%s.%%t" & set "HostOSVersion=%%s")
if "%HostVersion%" equ "10.0" if "%HostBuild%" geq "22000" set "HostOSVersion=11"
set "HostOSName=%W% %HostOSVersion% %HostEdition%"
Reg Unload HKLM\%TS% >nul 2>&1
goto :eof