@echo off
chcp 65001 >nul

if "%~1" == "" goto :EOF
cd "%~1" 1>nul 2>nul || goto :EOF

set /p key=请输入间隔字符：
if not defined key set key= *
echo.

set "File=%TMP%\BulidDIR"
dir /A:-D /B 1>"%File%" 2>nul
for /f "usebackq delims=" %%i in ("%File%") do (
	for /f "tokens=1,2 delims=." %%a in ("%%i") do (
		if /i "%%a" == "md5" (
			set mode=MD5
			set "HashFile=%%i"
			goto Check
		)
		if /i "%%a" == "sha1" (
			set mode=SHA1
			set "HashFile=%%i"
			goto Check
		)
		if /i "%%a" == "sha256" (
			set mode=SHA256
			set "HashFile=%%i"
			goto Check
		)
		if /i "%%b" == "md5" (
			set mode=MD5
			set "HashFile=%%i"
			goto Check
		)
		if /i "%%b" == "sha1" (
			set mode=SHA1
			set "HashFile=%%i"
			goto Check
		)
		if /i "%%b" == "sha256" (
			set mode=SHA256
			set "HashFile=%%i"
			goto Check
		)
	)
)

set /p mode=请输入校验模式：
if not defined mode set mode=MD5
echo.
if /i "%mode%" == "md5" (
	set mode=MD5
	goto modeOK
)
if /i "%mode%" == "sha1" (
	set mode=SHA1
	goto modeOK
)
if /i "%mode%" == "sha256" (
	set mode=SHA256
	goto modeOK
)
goto :EOF
:modeOK

set BS="prompt $H & echo on & for %%B in (1) do rem"
for /f %%A in ('%BS%') do set "BS=%%A"
set "Action=%BS% 1.生成  2.解析  "
set /p Action=%Action% && echo.
if "%Action%" == "1" goto Build
if "%Action%" == "2" goto Check
goto :EOF

:Build
set HashFile=%mode%.hash
empty 1>%HashFile% 2>nul
set "File=%TMP%\BulidDIR"
dir /A:-D /B /S | findstr /v /i /l /e "\%HashFile%" >"%File%"
for /f %%C in ('type "%File%" ^| find /c /v ""') do (
	set "total=%%C" && set "count=0"
)
set "Back=Clean"
set "ProcessLineStart=Build_Line"
goto WalkEachLine
:Build_Line
set "File=%Value%"
call set "File=%%File:%~1\=%%"
set "Back=%ProcessLineFinish%"
set /a count=%count%+1
set /p=%count%/%total% Building "%File%" ...<nul
goto WriteHash

:Check
if not defined HashFile (
	set "HashFile=请输入校验文件名："
	set /p HashFile=%HashFile% && echo.
)
if not exist %HashFile% goto :EOF

set /a Check_Num=1
set "File=%HashFile%"
set "Back=Check_Back"
set "ProcessLineStart=Check_Line"
goto WalkEachLine
:Check_Line
set "Check_Value=%Value%"
call set "Value=%%Value:%key%=*%%"
for /f "tokens=1,2 delims=*" %%i in ("%Value%") do (
	set "Value=%%i" && set "File=%%j"
)
if not defined File (
	echo 异常：%Check_Num%: "%Check_Value%"
	echo 提示：间隔字符可能输入错误？
	goto Clean
)
set /p=Checking "%File%" ...<nul
set /a Check_Num=%Check_Num%+1
if not exist "%File%" (
	echo [MISS]
	set "Check_MISS=TRUE"
	goto %ProcessLineFinish%
)
set "Back=Check_CheckHash"
goto CheckHash
:Check_CheckHash
echo [%Value%]
if "%Value%" == "FALSE" (
	set "Check_FALSE=TRUE"
)
goto %ProcessLineFinish%
:Check_Back
echo.
if "%Check_FALSE%" == "TRUE" (
	echo - 存在严重异常问题！
	goto Clean
)
if "%Check_MISS%" == "TRUE" (
	echo - 存在警告缺失问题？
	goto Clean
)
echo - 所有文件均无异常！
echo. && set /p Ans=删除校验文件？
if not defined Ans set Ans=y
if /i "%Ans%" == "y" (
	del /f "%HashFile%" >nul 2>nul
)

:Clean
del /f "%TMP%\BulidDIR" >nul 2>nul
del /f "%TMP%\BatValue" >nul 2>nul

:Finish
echo. && set /p=请按任意键继续. . . 
goto :EOF


:SaveValue

if not defined Back goto :EOF
if not defined Value goto %Back%
echo !Value!>"%TMP%\BatValue"
goto %Back%


:BackValue

if not defined Back goto :EOF
for /f "usebackq delims=" %%i in ("%TMP%\BatValue") do (
	set "Value=%%i"
)
goto %Back%


:GetFileNum

if not defined Back goto :EOF
if not defined File goto %Back%
set "BackBackup_GetFileNum=%Back%"
set "Back=GetFileNum_Save"
set /a Value=0
set "GetFileNum_File=%File:"=%"
setlocal enabledelayedexpansion
for /f "usebackq delims=" %%i in ("%GetFileNum_File%") do (
	set /a Value=!Value!+1
)
goto SaveValue
:GetFileNum_Save
endlocal
set "Back=GetFileNum_Back"
goto BackValue
:GetFileNum_Back
set "Num=%Value%"
goto %BackBackup_GetFileNum%


:WalkEachLine

if not defined Back goto :EOF
if not defined File goto %Back%
if not defined ProcessLineStart goto %Back%
set "BackBackup_WalkEachLine=%Back%"
set "Back=WalkEachLine_GetFileNum"
goto GetFileNum
:WalkEachLine_GetFileNum
set WalkEachLine_Num=%Num%
set /a WalkEachLine_Point=0
set "WalkEachLine_File=%File:"=%"
:WalkEachLine_LineLoop
if "%WalkEachLine_Point%" == "0" (
	set "Params=usebackq delims="
) else (
	set "Params=usebackq skip=%WalkEachLine_Point% delims="
)
for /f "%Params%" %%i in ("%WalkEachLine_File%") do (
	set "Value=%%i" && goto WalkEachLine_LineOut
)
:WalkEachLine_LineOut
set "ProcessLineFinish=WalkEachLine_Next"
goto %ProcessLineStart%
:WalkEachLine_Next
set /a WalkEachLine_Point=%WalkEachLine_Point%+1
if not %WalkEachLine_Point% == %WalkEachLine_Num% (
	goto WalkEachLine_LineLoop
)
goto %BackBackup_WalkEachLine%


:WriteHash

if not defined Back goto :EOF
if not defined File goto %Back%
if not defined HashFile goto %Back%
setlocal enabledelayedexpansion
for /f "skip=1" %%i in ('certutil -hashfile "!File!" %mode%') do (
	echo. && echo %%i%key%!File!>>%HashFile%
	endlocal && goto %Back%
)


:CheckHash

if not defined Back goto :EOF
if not defined File goto %Back%
if not defined Value goto %Back%
setlocal enabledelayedexpansion
for /f "skip=1" %%i in ('certutil -hashfile "!File!" %mode%') do (
	endlocal
	if "%%i" == "%Value%" (
		set "Value=RIGHT"
	) else (
		set "Value=FALSE"
	)
	goto %Back%
)
