@echo off
REM XenTools bugtool generator - Beta 1.2 by Blaine A. Anaya
REM This script collects necessary files used to identify where a XenTools installation issue has occurred
REM and places them in a ZIP file determined at runtime.
REM Usage: xtbugtool.bat <Destination Path for ZIP file>
REM 14 August 2015 - Added Windows Server 2012 to version list
REM 17 August 2015 - Bugfix to correct copy of programfiles and programdata into ZIP
REM 20 August 2015 - Added Registry collection, modified log file copy to include installer directory and 32-bit and 64-bit directories

IF "%1"=="" GOTO usage
set zippath=%1
for /f "tokens=2,3,4,5,6 usebackq delims=:/ " %%a in ('%date% %time%') do set dtstring=%%c.%%a.%%b-%%d%%e
set bugpath=%temp%\%dtstring%
mkdir %bugpath%
REM Set XenTools install directory as identified in the registry
FOR /F "usebackq skip=2 tokens=1-2*" %%A IN (`REG QUERY HKLM\SOFTWARE\Citrix\Xentools /v Install_Dir 2^>nul`) DO (
    set XTInstallDir=%%C
	)
REM Collect XenTools version information from registry
FOR /F "usebackq skip=2 tokens=1-3" %%A IN (`REG QUERY HKLM\SOFTWARE\Citrix\Xentools /v MajorVersion 2^>nul`) DO (
    set /a MajorVerReg=%%C
)

FOR /F "usebackq skip=2 tokens=1-3" %%A IN (`REG QUERY HKLM\SOFTWARE\Citrix\Xentools /v MinorVersion 2^>nul`) DO (
    set /a MinorVerReg=%%C
)
FOR /F "usebackq skip=2 tokens=1-3" %%A IN (`REG QUERY HKLM\SOFTWARE\Citrix\Xentools /v MicroVersion 2^>nul`) DO (
    set /a MicroVerReg=%%C
)
FOR /F "usebackq skip=2 tokens=1-3" %%A IN (`REG QUERY HKLM\SOFTWARE\Citrix\Xentools /v BuildVersion 2^>nul`) DO (
    set /a BuildVerReg=%%C
)

REM Collect important registry entries
mkdir %bugpath%\registry
reg export "HKLM\SYSTEM\CurrentControlSet\Control" "%bugpath%\registry\control.reg" /y > NUL 2>&1
reg export "HKLM\SOFTWARE\Citrix" "%bugpath%\registry\SWcitrix.reg" /y > NUL 2>&1
reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "%bugpath%\registry\uninstall.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xenvif" "%bugpath%\registry\xenvif.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xenvbd" "%bugpath%\registry\xenvbd.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xenSvc" "%bugpath%\registry\xensvc.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xennet" "%bugpath%\registry\xennet.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xenlite" "%bugpath%\registry\xenlite.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xeniface" "%bugpath%\registry\xeniface.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xenfilt" "%bugpath%\registry\xenfilt.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xendisk" "%bugpath%\registry\xendisk.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xenbus" "%bugpath%\registry\xenbus.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\xen" "%bugpath%\registry\xen.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\tcpip" "%bugpath%\registry\tcpip.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\tcpip6" "%bugpath%\registry\tcpip6.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\netbt" "%bugpath%\registry\netbt.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation" "%bugpath%\registry\lanmanworkstation.reg" /y > NUL 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Enum" "%bugpath%\registry\enum.reg" /y > NUL 2>&1

REM Check for 64 Bit Keys
reg query HKLM\Software\Wow6432node\Citrix > NUL 2>&1
if %ERRORLEVEL% == 0 (
reg export "HKLM\Software\Wow6432node\Citrix\XenToolsInstaller" "%bugpath%\registry\XenToolsInstaller.reg" /y > NUL 2>&1
)
	
REM Identify Running OS then run collection commands for that version

ver | find "XP" > nul
if %ERRORLEVEL% == 0 goto ver_xp

ver | find "2000" > nul
if %ERRORLEVEL% == 0 goto ver_2000

ver | find "NT" > nul
if %ERRORLEVEL% == 0 goto ver_nt

if not exist %SystemRoot%\system32\systeminfo.exe goto warnthenexit

REM set vmosname=systeminfo |find "OS Name"
systeminfo | find "OS Name" > %bugpath%\osname.txt

FOR /F "usebackq delims=: tokens=2" %%i IN (%bugpath%\osname.txt) DO set vers=%%i

echo %vers% | find "Windows 8" > nul
if %ERRORLEVEL% == 0 goto ver_8

echo %vers% | find "Windows 7" > nul
if %ERRORLEVEL% == 0 goto ver_7

echo %vers% | find "2012" > nul
if %ERRORLEVEL% == 0 goto ver_2012

echo %vers% | find "Windows Server 2008" > nul
if %ERRORLEVEL% == 0 goto ver_2008

echo %vers% | find "2003" > nul
if %ERRORLEVEL% == 0 goto ver_2003

echo %vers% | find "Windows Vista" > nul
if %ERRORLEVEL% == 0 goto ver_vista

goto warnthenexit

:ver_8
:Run Windows 8 specific commands here.
echo Windows 8
cd %bugpath%
echo %MajorVerReg%.%MinorVerReg%.%MicroVerReg%.%BuildVerReg% > xt-reg-version.txt
echo %XTInstallDir% > xt-install-dir.txt
echo Generating MSInfo file as NFO - human readable version of data
msinfo32 /nfo msinfo.nfo
echo Generating MSInfo file as text file - script friendly version of data
msinfo32 /report msinfo.txt
echo Copying logfiles to bugtool...
mkdir programfiles64
mkdir programfiles
mkdir programdata
copy c:\programdata\citrix\* programdata  > NUL 2>&1
copy "c:\Program Files (x86)\Citrix\XenTools\*.txt" programfiles64  > NUL 2>&1
copy "c:\Program Files (x86)\Citrix\XenTools\*.log" programfiles64  > NUL 2>&1
copy "C:\Program Files (x86)\Citrix\XenTools\Installer\*.config" programfiles64  > NUL 2>&1
copy "C:\Program Files (x86)\Citrix\XenTools\Installer\*.install*" programfiles64  > NUL 2>&1
copy "c:\Program Files\Citrix\XenTools\*.txt" programfiles  > NUL 2>&1
copy "c:\Program Files\Citrix\XenTools\*.log" programfiles  > NUL 2>&1
copy "C:\Program Files\Citrix\XenTools\Installer\*.config" programfiles  > NUL 2>&1
copy "C:\Program Files\Citrix\XenTools\Installer\*.install*" programfiles  > NUL 2>&1
xcopy /Y /C C:\Windows\Inf\setupapi.dev.log  > NUL 2>&1
xcopy /Y /C C:\Windows\Inf\setupapi.setup.log  > NUL 2>&1
echo Capturing pnputil -e output...
pnputil.exe -e > pnputil-e.out
echo Capturing state of WMI repository (will fail if not ran as administrator)...
C:\Windows\System32\wbem\winmgmt /verifyrepository > wmistate.out
echo Exporting System event log...
wevtutil epl System system.evtx
echo Exporting Application event log...
wevtutil epl Application application.evtx
cd ..
echo Finalizing process and creating ZIP file...
goto zipit

:ver_2012
:Run Windows 2012 specific commands here.
echo Windows 2012
cd %bugpath%
echo %MajorVerReg%.%MinorVerReg%.%MicroVerReg%.%BuildVerReg% > xt-reg-version.txt
echo %XTInstallDir% > xt-install-dir.txt
echo Generating MSInfo file as NFO - human readable version of data
msinfo32 /nfo msinfo.nfo
echo Generating MSInfo file as text file - script friendly version of data
msinfo32 /report msinfo.txt
echo Copying logfiles to bugtool...
mkdir programfiles64
mkdir programfiles
mkdir programdata
copy c:\programdata\citrix\* programdata > NUL 2>&1
copy "c:\Program Files (x86)\Citrix\XenTools\*.txt" programfiles64 > NUL 2>&1
copy "c:\Program Files (x86)\Citrix\XenTools\*.log" programfiles64 > NUL 2>&1
copy "C:\Program Files (x86)\Citrix\XenTools\Installer\*.config" programfiles64 > NUL 2>&1
copy "C:\Program Files (x86)\Citrix\XenTools\Installer\*.install*" programfiles64 > NUL 2>&1
copy "c:\Program Files\Citrix\XenTools\*.txt" programfiles > NUL 2>&1
copy "c:\Program Files\Citrix\XenTools\*.log" programfiles > NUL 2>&1
copy "C:\Program Files\Citrix\XenTools\Installer\*.config" programfiles > NUL 2>&1
copy "C:\Program Files\Citrix\XenTools\Installer\*.install*" programfiles > NUL 2>&1
xcopy /Y /C C:\Windows\Inf\setupapi.dev.log
xcopy /Y /C C:\Windows\Inf\setupapi.setup.log
echo Capturing pnputil -e output...
pnputil.exe -e > pnputil-e.out
echo Capturing state of WMI repository (will fail if not ran as administrator)...
C:\Windows\System32\wbem\winmgmt /verifyrepository > wmistate.out
echo Exporting System event log...
wevtutil epl System system.evtx
echo Exporting Application event log...
wevtutil epl Application application.evtx
cd ..
echo Finalizing process and creating ZIP file...
goto zipit


:ver_7
:Run Windows 7 specific commands here.
echo Windows 7
cd %bugpath%
echo %MajorVerReg%.%MinorVerReg%.%MicroVerReg%.%BuildVerReg% > xt-reg-version.txt
echo %XTInstallDir% > xt-install-dir.txt
echo Generating MSInfo file as NFO - human readable version of data
msinfo32 /nfo msinfo.nfo
echo Generating MSInfo file as text file - script friendly version of data
msinfo32 /report msinfo.txt
echo Copying logfiles to bugtool...
mkdir programfiles64
mkdir programfiles
mkdir programdata
copy c:\programdata\citrix\* programdata > NUL 2>&1
copy "c:\Program Files (x86)\Citrix\XenTools\*.txt" programfiles64 > NUL 2>&1
copy "c:\Program Files (x86)\Citrix\XenTools\*.log" programfiles64 > NUL 2>&1
copy "C:\Program Files (x86)\Citrix\XenTools\Installer\*.config" programfiles64 > NUL 2>&1
copy "C:\Program Files (x86)\Citrix\XenTools\Installer\*.install*" programfiles64 > NUL 2>&1
copy "c:\Program Files\Citrix\XenTools\*.txt" programfiles > NUL 2>&1
copy "c:\Program Files\Citrix\XenTools\*.log" programfiles > NUL 2>&1
copy "C:\Program Files\Citrix\XenTools\Installer\*.config" programfiles > NUL 2>&1
copy "C:\Program Files\Citrix\XenTools\Installer\*.install*" programfiles > NUL 2>&1
xcopy /Y /C C:\Windows\Inf\setupapi.dev.log
xcopy /Y /C C:\Windows\Inf\setupapi.setup.log
echo Capturing pnputil -e output...
pnputil.exe -e > pnputil-e.out
echo Capturing state of WMI repository (will fail if not ran as administrator)...
C:\Windows\System32\wbem\winmgmt /verifyrepository > wmistate.out
echo Exporting System event log...
wevtutil epl System system.evtx
echo Exporting Application event log...
wevtutil epl Application application.evtx
cd ..
echo Finalizing process and creating ZIP file...
goto zipit


:ver_2008
:Run Windows Server 2008 specific commands here.
echo Windows Server 2008
goto exit

:ver_vista
:Run Windows Vista specific commands here.
echo Windows Vista
goto exit

:ver_2003
:Run Windows Server 2003 specific commands here.
echo Windows Server 2003
cd %bugpath%
echo %MajorVerReg%.%MinorVerReg%.%MicroVerReg%.%BuildVerReg% > xt-reg-version.txt
echo %XTInstallDir% > xt-install-dir.txt
echo Generating MSInfo file as NFO - human readable version of data
msinfo32 /nfo msinfo.nfo
echo Generating MSInfo file as text file - script friendly version of data
msinfo32 /report msinfo.txt
echo Copying logfiles to bugtool...
mkdir programfiles64
mkdir programfiles
mkdir programdata
copy c:\programdata\citrix\* programdata  > NUL 2>&1
copy "c:\Program Files (x86)\Citrix\XenTools\*.txt" programfiles64 > NUL 2>&1
copy "c:\Program Files (x86)\Citrix\XenTools\*.log" programfiles64 > NUL 2>&1
copy "C:\Program Files (x86)\Citrix\XenTools\Installer\*.config" programfiles64 > NUL 2>&1
copy "C:\Program Files (x86)\Citrix\XenTools\Installer\*.install*" programfiles64 > NUL 2>&1
copy "c:\Program Files\Citrix\XenTools\*.txt" programfiles > NUL 2>&1
copy "c:\Program Files\Citrix\XenTools\*.log" programfiles > NUL 2>&1
copy "C:\Program Files\Citrix\XenTools\Installer\*.config" programfiles > NUL 2>&1
copy "C:\Program Files\Citrix\XenTools\Installer\*.install*" programfiles > NUL 2>&1
xcopy /Y /C C:\Windows\Inf\setupapi.dev.log
xcopy /Y /C C:\Windows\Inf\setupapi.setup.log
echo Capturing pnputil -e output...
pnputil.exe -e > pnputil-e.out
echo Capturing state of WMI repository (will fail if not ran as administrator)...
C:\Windows\System32\wbem\winmgmt /verifyrepository > wmistate.out
echo Exporting System event log...
wevtutil epl System system.evtx
echo Exporting Application event log...
wevtutil epl Application application.evtx
cd ..
echo Finalizing process and creating ZIP file...
goto zipit

:ver_xp
:Run Windows XP specific commands here.
echo Windows XP
goto exit

:ver_2000
:Run Windows 2000 specific commands here.
echo Windows 2000
goto exit

:ver_nt
:Run Windows NT specific commands here.
echo Windows NT
goto exit

:warnthenexit
echo Machine undetermined.

:zipit
echo Set objArgs = WScript.Arguments > _zipIt.vbs
echo InputFolder = objArgs(0) >> _zipIt.vbs
echo ZipFile = objArgs(1) >> _zipIt.vbs
echo CreateObject("Scripting.FileSystemObject").CreateTextFile(ZipFile, True).Write "PK" ^& Chr(5) ^& Chr(6) ^& String(18, vbNullChar) >> _zipIt.vbs
echo Set objShell = CreateObject("Shell.Application") >> _zipIt.vbs
echo Set source = objShell.NameSpace(InputFolder).Items >> _zipIt.vbs
echo objShell.NameSpace(ZipFile).CopyHere(source) >> _zipIt.vbs
echo wScript.Sleep 2000 >> _zipIt.vbs
CScript  _zipIt.vbs  %bugpath%  %zippath%\xt-bugtool-%dtstring%.zip
del _zipIt.vbs
rmdir /S /Q %bugpath%
goto exit

:usage
IF "%1"=="" echo "USAGE: xtbugtool.bat <Destination Path for ZIP file>"

:exit
