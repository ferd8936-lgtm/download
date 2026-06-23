@echo off
chcp 65001 >nul
title 셉시스템 무중단 보안 셋팅 툴

:: 관리자 권한 획득 (스케줄러 및 방화벽 설정을 위해 필수)
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /B
)
cd /d "%~dp0"

:MENU
cls
echo ==========================================================
echo        [ 셉시스템(SEB) 무중단 보안 셋팅 툴 ]
echo ==========================================================
echo  [ 윈도우 업데이트 차단 (WUB) ]
echo   1. 10분 주기 차단 스케줄러 [등록] (즉시 차단 적용)
echo   2. 10분 주기 차단 스케줄러 [취소]
echo ----------------------------------------------------------
echo  [ 강력 방화벽 셋팅 (인터넷 차단) ]
echo   3. 보안 모드 [적용] (러스트데스크, 셉시스템만 허용)
echo   4. 일반 모드 [적용] (모든 인터넷 허용)
echo ==========================================================
echo   0. 프로그램 종료
echo ==========================================================
set /p choice="원하는 작업 번호를 입력하세요 (0~4): "

if "%choice%"=="1" goto WUB_ON
if "%choice%"=="2" goto WUB_OFF
if "%choice%"=="3" goto FW_ON
if "%choice%"=="4" goto FW_OFF
if "%choice%"=="0" exit
goto MENU

:WUB_ON
echo.
set "WUB_EXE="
if exist "%~dp0Wub_x64.exe" set "WUB_EXE=%~dp0Wub_x64.exe"
if exist "%~dp0Wub.exe" set "WUB_EXE=%~dp0Wub.exe"

if defined WUB_EXE (
    echo [1/2] 즉시 WUB 차단 명령을 실행합니다...
    :: 대기하지 않고 즉시 WUB 차단 1회 강제 실행!
    start /wait "" "%WUB_EXE%" /D /P
    
    echo [2/2] 10분 주기 차단 스케줄러를 등록합니다...
    schtasks /create /tn "SEB_WUB_Blocker" /tr "\"%WUB_EXE%\" /D /P" /sc minute /mo 10 /ru "SYSTEM" /f >nul 2>&1
    echo ✅ [등록 완료] 즉시 업데이트 차단이 적용되었으며, 이후 10분마다 알아서 유지됩니다!
) else (
    echo ❌ [오류] 현재 폴더에 Wub.exe 또는 Wub_x64.exe 파일이 없습니다!
)
pause
goto MENU

:WUB_OFF
echo.
schtasks /delete /tn "SEB_WUB_Blocker" /f >nul 2>&1
echo ✅ [취소 완료] 10분 주기 WUB 차단 스케줄러가 삭제되었습니다.
pause
goto MENU

:FW_ON
echo.
echo 기존 방화벽 규칙 초기화 중...
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound >nul
netsh advfirewall firewall delete rule name="Allow_RustDesk_IP" >nul 2>&1
netsh advfirewall firewall delete rule name="Allow_SEB_App" >nul 2>&1
netsh advfirewall firewall delete rule name="Allow_Local_Network" >nul 2>&1

echo 필수 허용 규칙 등록 중...
:: 1. 러스트데스크 서버 IP 허용 (1.234.66.199)
netsh advfirewall firewall add rule name="Allow_RustDesk_IP" dir=out action=allow remoteip=1.234.66.199 >nul
:: 2. 셉시스템 프로그램 외부 통신 자체 허용
netsh advfirewall firewall add rule name="Allow_SEB_App" dir=out action=allow program="%~dp0ferdseb-r.v2.exe" enable=yes >nul
:: 3. 같은 공유기 대역 내부 통신 허용 (화재수신기와 로컬 IP 통신 시 필수)
netsh advfirewall firewall add rule name="Allow_Local_Network" dir=out action=allow remoteip=LocalSubnet >nul

echo ✅ [보안 모드 적용 완료] 러스트데스크 및 셉시스템 외의 모든 외부 인터넷이 철저히 차단되었습니다!
pause
goto MENU

:FW_OFF
echo.
echo 방화벽 설정을 일반 상태로 되돌립니다...
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound >nul
netsh advfirewall firewall delete rule name="Allow_RustDesk_IP" >nul 2>&1
netsh advfirewall firewall delete rule name="Allow_SEB_App" >nul 2>&1
netsh advfirewall firewall delete rule name="Allow_Local_Network" >nul 2>&1
echo ✅ [일반 모드 적용 완료] 모든 인터넷을 정상적으로 사용할 수 있습니다.
pause
goto MENU