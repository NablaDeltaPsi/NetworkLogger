@echo off
mode con: cols=40 lines=9
title NetworkLogger

REM Settings
SET server=google.de
SET repetitionTimeout="10"
SET failureThreshold=6

REM Initializations
SET firstRun=1
SET pingTime=0
SET lastFail=-
SET failsSinceSuccess=0
SET successesSinceFailure=-1
SET numberSuccess=0
SET numberFails=0
SET numberFailures=0

REM Check internet connection
:check
SET dateTime=%date% %time%
cls
ECHO NetworkLogger (%server%)
ECHO Time: %dateTime%
ECHO Successes: %numberSuccess% (%successesSinceFailure% since failure)
ECHO Fails: %numberFails% (%failsSinceSuccess% since success)
ECHO Failures: %numberFailures%
ECHO Last fail: %lastFail%
IF %pingTime% GTR 0 (
	ECHO Success: %pingTime%ms
) ELSE (
	ECHO No connection!
)

IF %firstRun% EQU 1 (
	SET firstRun=0
) ELSE (
	TIMEOUT /t %repetitionTimeout%>nul
)

REM Print complete answer and overwrite into pingAnswer (keep last line)
REM Debugging: DO (ECHO %%G & SET pingAnswer=%%G)
SET pingAnswer=None
SET pingTime=0
FOR /F "delims=" %%G in ('ping -n 2 %server% ^| findstr /r /c:"[0-9] *ms"') DO (SET pingAnswer=%%G)

REM Get everything after third equal (=)
FOR /f "tokens=4 delims==" %%a in ("%pingAnswer%") do (SET pingTime=%%a)

REM Get everything before first m (ms)
FOR /f "tokens=1 delims=m" %%a in ("%pingTime%") do (SET pingTime=%%a)

REM Strip leading whitespace
CALL :TRIM %pingTime% pingTime

IF %pingTime% EQU 0 GOTO fail
GOTO success

:success
color 0A
SET /a numberSuccess+=1
SET failsSinceSuccess=0
IF %successesSinceFailure% LEQ 0 (
	SET successesSinceFailure=1
) ELSE (
	SET /a successesSinceFailure+=1
)
IF NOT EXIST "NetworkLogger" MKDIR "NetworkLogger"
ECHO %dateTime%;%pingTime% >> NetworkLogger/NetworkLog_%date:~6,4%_%date:~3,2%_%date:~0,2%.txt
GOTO check

:fail
color 0C
SET /a numberFails+=1
SET /a failsSinceSuccess+=1
IF %successesSinceFailure% LEQ %failureThreshold% (
	SET successesSinceFailure=0
)
IF %failsSinceSuccess% EQU %failureThreshold% (
	IF %numberFailures% EQU 0 (
		SET /a numberFailures+=1
		SET successesSinceFailure=0
	)
	IF %successesSinceFailure% GEQ %failureThreshold% (
		SET /a numberFailures+=1
		SET successesSinceFailure=0
	)
)
SET lastFail=%date%-%time%
IF NOT EXIST "NetworkLogger" MKDIR "NetworkLogger"
ECHO %dateTime%;9999 >> NetworkLogger/NetworkLog_%date:~6,4%_%date:~3,2%_%date:~0,2%.txt
GOTO check

:TRIM
SET %2=%1
GOTO :EOF