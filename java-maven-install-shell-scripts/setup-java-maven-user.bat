@echo off
setlocal EnableDelayedExpansion

:: ============================================================================
:: User-Level Java 21 and Maven 3.9.15 Installation Script for Windows
:: No administrator privileges required
:: Installs to the current user's profile directory and configures USER
:: environment variables only.
:: Supports Windows 10 and Windows 11.
:: ============================================================================

title User-Level Java 21 and Maven 3.9.15 Setup

:: Color placeholders for echoed status labels
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "RESET=[0m"

:: Versions
set "JAVA_VERSION=21"
set "MAVEN_VERSION=3.9.15"
set "MAVEN_DIR_NAME=apache-maven-3.9.15"

:: Installation paths in user profile
set "JAVA_INSTALL_DIR=%USERPROFILE%\Java\jdk-21"
set "MAVEN_BASE_DIR=%USERPROFILE%\Apache\maven"
set "MAVEN_INSTALL_DIR=%MAVEN_BASE_DIR%\%MAVEN_DIR_NAME%"
set "TEMP_DIR=%TEMP%\java-maven-user-setup"

:: Download URLs
set "JAVA_URL=https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip"
set "MAVEN_URL=https://archive.apache.org/dist/maven/maven-3/3.9.15/binaries/apache-maven-3.9.15-bin.zip"

:: Working files
set "JAVA_ZIP=%TEMP_DIR%\jdk-21_windows-x64_bin.zip"
set "MAVEN_ZIP=%TEMP_DIR%\apache-maven-3.9.15-bin.zip"
set "JAVA_EXTRACT_DIR=%TEMP_DIR%\java-extracted"
set "MAVEN_EXTRACT_DIR=%TEMP_DIR%\maven-extracted"

echo.
echo %BLUE%============================================================%RESET%
echo %BLUE%User-Level Java 21 and Maven 3.9.15 Installer%RESET%
echo %BLUE%============================================================%RESET%
echo %GREEN%This script does NOT require Administrator privileges.%RESET%
echo %YELLOW%Everything will be installed in your user profile:%RESET%
echo   Java  : %JAVA_INSTALL_DIR%
echo   Maven : %MAVEN_INSTALL_DIR%
echo.
echo %YELLOW%USER environment variables will be configured using PowerShell:%RESET%
echo   JAVA_HOME
echo   MAVEN_HOME
echo   PATH ^(user scope only^)
echo.

:: ============================================================================
:: Create required directories
:: ============================================================================
echo %BLUE%Preparing directories...%RESET%
if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%"
    echo %GREEN%Created temporary directory: %TEMP_DIR%%RESET%
) else (
    echo %YELLOW%Temporary directory already exists: %TEMP_DIR%%RESET%
)

if not exist "%USERPROFILE%\Java" (
    mkdir "%USERPROFILE%\Java"
    echo %GREEN%Created Java base directory.%RESET%
) else (
    echo %YELLOW%Java base directory already exists.%RESET%
)

if not exist "%MAVEN_BASE_DIR%" (
    mkdir "%MAVEN_BASE_DIR%"
    echo %GREEN%Created Maven base directory.%RESET%
) else (
    echo %YELLOW%Maven base directory already exists.%RESET%
)
echo.

:: ============================================================================
:: Check Java installation
:: ============================================================================
set "JAVA_ALREADY_INSTALLED=0"
echo %BLUE%============================================================%RESET%
echo %BLUE%Checking Java 21 installation...%RESET%
echo %BLUE%============================================================%RESET%
if exist "%JAVA_INSTALL_DIR%\bin\java.exe" (
    "%JAVA_INSTALL_DIR%\bin\java.exe" --version >nul 2>&1
    if !errorlevel! equ 0 (
        echo %GREEN%Java 21 already installed at: %JAVA_INSTALL_DIR%%RESET%
        set "JAVA_ALREADY_INSTALLED=1"
    ) else (
        echo %YELLOW%Existing Java directory found but verification failed. Reinstalling.%RESET%
    )
) else (
    echo %YELLOW%Java 21 not found. Installation will proceed.%RESET%
)
echo.

:: ============================================================================
:: Download and install Java
:: ============================================================================
if !JAVA_ALREADY_INSTALLED! equ 0 (
    echo %BLUE%Downloading Java 21 with PowerShell ^(TLS 1.2^)...%RESET%
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%JAVA_URL%' -OutFile '%JAVA_ZIP%' -UseBasicParsing; Write-Host '[SUCCESS] Java download completed.' -ForegroundColor Green; exit 0 } catch { Write-Host '[ERROR] Failed to download Java 21.' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 } }"
    if !errorlevel! neq 0 (
        echo %RED%Java download failed.%RESET%
        goto :cleanup_and_exit
    )

    if exist "%JAVA_EXTRACT_DIR%" rmdir /s /q "%JAVA_EXTRACT_DIR%"
    mkdir "%JAVA_EXTRACT_DIR%"

    echo %BLUE%Extracting Java 21 with PowerShell...%RESET%
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "& { $ProgressPreference = 'SilentlyContinue'; try { Expand-Archive -Path '%JAVA_ZIP%' -DestinationPath '%JAVA_EXTRACT_DIR%' -Force; Write-Host '[SUCCESS] Java archive extracted.' -ForegroundColor Green; exit 0 } catch { Write-Host '[ERROR] Failed to extract Java archive.' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 } }"
    if !errorlevel! neq 0 (
        echo %RED%Java extraction failed.%RESET%
        goto :cleanup_and_exit
    )

    set "EXTRACTED_JAVA_DIR="
    for /d %%i in ("%JAVA_EXTRACT_DIR%\jdk-*") do (
        set "EXTRACTED_JAVA_DIR=%%i"
    )

    if not defined EXTRACTED_JAVA_DIR (
        echo %RED%Could not locate extracted Java directory.%RESET%
        goto :cleanup_and_exit
    )

    if exist "%JAVA_INSTALL_DIR%" (
        echo %YELLOW%Removing previous Java installation for clean update...%RESET%
        rmdir /s /q "%JAVA_INSTALL_DIR%"
    )

    echo %BLUE%Installing Java 21 to %JAVA_INSTALL_DIR%...%RESET%
    move "!EXTRACTED_JAVA_DIR!" "%JAVA_INSTALL_DIR%" >nul
    if !errorlevel! neq 0 (
        echo %RED%Failed to move Java into final installation directory.%RESET%
        goto :cleanup_and_exit
    )
    echo %GREEN%Java 21 installed successfully.%RESET%
    echo.
)

:: ============================================================================
:: Check Maven installation
:: ============================================================================
set "MAVEN_ALREADY_INSTALLED=0"
echo %BLUE%============================================================%RESET%
echo %BLUE%Checking Maven 3.9.15 installation...%RESET%
echo %BLUE%============================================================%RESET%
if exist "%MAVEN_INSTALL_DIR%\bin\mvn.cmd" (
    "%MAVEN_INSTALL_DIR%\bin\mvn.cmd" --version >nul 2>&1
    if !errorlevel! equ 0 (
        echo %GREEN%Maven 3.9.15 already installed at: %MAVEN_INSTALL_DIR%%RESET%
        set "MAVEN_ALREADY_INSTALLED=1"
    ) else (
        echo %YELLOW%Existing Maven directory found but verification failed. Reinstalling.%RESET%
    )
) else (
    echo %YELLOW%Maven 3.9.15 not found. Installation will proceed.%RESET%
)
echo.

:: ============================================================================
:: Download and install Maven
:: ============================================================================
if !MAVEN_ALREADY_INSTALLED! equ 0 (
    echo %BLUE%Downloading Maven 3.9.15 with PowerShell ^(TLS 1.2^)...%RESET%
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%MAVEN_URL%' -OutFile '%MAVEN_ZIP%' -UseBasicParsing; Write-Host '[SUCCESS] Maven download completed.' -ForegroundColor Green; exit 0 } catch { Write-Host '[ERROR] Failed to download Maven 3.9.15.' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 } }"
    if !errorlevel! neq 0 (
        echo %RED%Maven download failed.%RESET%
        goto :cleanup_and_exit
    )

    if exist "%MAVEN_EXTRACT_DIR%" rmdir /s /q "%MAVEN_EXTRACT_DIR%"
    mkdir "%MAVEN_EXTRACT_DIR%"

    echo %BLUE%Extracting Maven 3.9.15 with PowerShell...%RESET%
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "& { $ProgressPreference = 'SilentlyContinue'; try { Expand-Archive -Path '%MAVEN_ZIP%' -DestinationPath '%MAVEN_EXTRACT_DIR%' -Force; Write-Host '[SUCCESS] Maven archive extracted.' -ForegroundColor Green; exit 0 } catch { Write-Host '[ERROR] Failed to extract Maven archive.' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 } }"
    if !errorlevel! neq 0 (
        echo %RED%Maven extraction failed.%RESET%
        goto :cleanup_and_exit
    )

    set "EXTRACTED_MAVEN_DIR="
    for /d %%i in ("%MAVEN_EXTRACT_DIR%\apache-maven-*") do (
        set "EXTRACTED_MAVEN_DIR=%%i"
    )

    if not defined EXTRACTED_MAVEN_DIR (
        echo %RED%Could not locate extracted Maven directory.%RESET%
        goto :cleanup_and_exit
    )

    if exist "%MAVEN_INSTALL_DIR%" (
        echo %YELLOW%Removing previous Maven installation for clean update...%RESET%
        rmdir /s /q "%MAVEN_INSTALL_DIR%"
    )

    echo %BLUE%Installing Maven 3.9.15 to %MAVEN_INSTALL_DIR%...%RESET%
    move "!EXTRACTED_MAVEN_DIR!" "%MAVEN_INSTALL_DIR%" >nul
    if !errorlevel! neq 0 (
        echo %RED%Failed to move Maven into final installation directory.%RESET%
        goto :cleanup_and_exit
    )
    echo %GREEN%Maven 3.9.15 installed successfully.%RESET%
    echo.
)

:: ============================================================================
:: Configure USER environment variables
:: ============================================================================
echo %BLUE%============================================================%RESET%
echo %BLUE%Configuring USER environment variables...%RESET%
echo %BLUE%============================================================%RESET%
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& { ^
        try { ^
            $javaHome = '%JAVA_INSTALL_DIR%'; ^
            $mavenHome = '%MAVEN_INSTALL_DIR%'; ^
            $javaBin = $javaHome + '\bin'; ^
            $mavenBin = $mavenHome + '\bin'; ^
            [Environment]::SetEnvironmentVariable('JAVA_HOME', $javaHome, 'User'); ^
            Write-Host '[SUCCESS] Set JAVA_HOME (User):' $javaHome -ForegroundColor Green; ^
            [Environment]::SetEnvironmentVariable('MAVEN_HOME', $mavenHome, 'User'); ^
            Write-Host '[SUCCESS] Set MAVEN_HOME (User):' $mavenHome -ForegroundColor Green; ^
            $currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User'); ^
            if ([string]::IsNullOrWhiteSpace($currentUserPath)) { $pathEntries = New-Object System.Collections.Generic.List[string] } else { $pathEntries = New-Object System.Collections.Generic.List[string]; $currentUserPath.Split(';') | ForEach-Object { if (-not [string]::IsNullOrWhiteSpace($_)) { [void]$pathEntries.Add($_) } } } ^
            if (-not ($pathEntries -contains $javaBin)) { $pathEntries.Insert(0, $javaBin); Write-Host '[SUCCESS] Added Java bin to user PATH.' -ForegroundColor Green } else { Write-Host '[WARNING] Java bin already present in user PATH.' -ForegroundColor Yellow } ^
            if (-not ($pathEntries -contains $mavenBin)) { $pathEntries.Insert(0, $mavenBin); Write-Host '[SUCCESS] Added Maven bin to user PATH.' -ForegroundColor Green } else { Write-Host '[WARNING] Maven bin already present in user PATH.' -ForegroundColor Yellow } ^
            $newUserPath = ($pathEntries | Select-Object -Unique) -join ';'; ^
            [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User'); ^
            Write-Host '[SUCCESS] User PATH updated successfully.' -ForegroundColor Green; ^
            exit 0; ^
        } catch { ^
            Write-Host '[ERROR] Failed to configure user environment variables.' -ForegroundColor Red; ^
            Write-Host $_.Exception.Message -ForegroundColor Red; ^
            exit 1; ^
        } ^
    }"
if !errorlevel! neq 0 (
    echo %RED%Failed to configure USER environment variables.%RESET%
    goto :cleanup_and_exit
)
echo.

:: Update current CMD session for immediate verification
set "JAVA_HOME=%JAVA_INSTALL_DIR%"
set "MAVEN_HOME=%MAVEN_INSTALL_DIR%"
echo %YELLOW%Updating current session PATH for verification...%RESET%
echo %PATH% | find /I "%JAVA_INSTALL_DIR%\bin" >nul
if errorlevel 1 set "PATH=%JAVA_INSTALL_DIR%\bin;%PATH%"
echo %PATH% | find /I "%MAVEN_INSTALL_DIR%\bin" >nul
if errorlevel 1 set "PATH=%MAVEN_INSTALL_DIR%\bin;%PATH%"
echo %GREEN%Current session updated.%RESET%
echo.

:: ============================================================================
:: Verify installation
:: ============================================================================
echo %BLUE%============================================================%RESET%
echo %BLUE%Verifying installation...%RESET%
echo %BLUE%============================================================%RESET%
set "VERIFICATION_FAILED=0"

echo %YELLOW%JAVA_HOME:%RESET%
echo   %JAVA_HOME%
echo %YELLOW%MAVEN_HOME:%RESET%
echo   %MAVEN_HOME%
echo.

echo %YELLOW%Java version:%RESET%
"%JAVA_INSTALL_DIR%\bin\java.exe" --version
if !errorlevel! neq 0 (
    echo %RED%Java verification failed.%RESET%
    set "VERIFICATION_FAILED=1"
) else (
    echo %GREEN%Java verification successful.%RESET%
)
echo.

echo %YELLOW%Maven version:%RESET%
"%MAVEN_INSTALL_DIR%\bin\mvn.cmd" --version
if !errorlevel! neq 0 (
    echo %RED%Maven verification failed.%RESET%
    set "VERIFICATION_FAILED=1"
) else (
    echo %GREEN%Maven verification successful.%RESET%
)
echo.

:cleanup_and_exit
echo %BLUE%Cleaning up temporary files...%RESET%
if exist "%TEMP_DIR%" (
    rmdir /s /q "%TEMP_DIR%"
    echo %GREEN%Temporary files removed.%RESET%
) else (
    echo %YELLOW%No temporary files to remove.%RESET%
)
echo.

echo %BLUE%============================================================%RESET%
echo %BLUE%Installation Summary%RESET%
echo %BLUE%============================================================%RESET%
if "%VERIFICATION_FAILED%"=="1" (
    echo %RED%Setup completed with verification errors.%RESET%
    echo %YELLOW%Review the messages above and re-run the script if needed.%RESET%
    echo.
    echo %YELLOW%Target locations:%RESET%
    echo   Java  : %JAVA_INSTALL_DIR%
    echo   Maven : %MAVEN_INSTALL_DIR%
    echo.
    echo %GREEN%Reminder:%RESET%
    echo %YELLOW%Restart your terminal after installation so PATH changes take effect.%RESET%
    pause
    exit /b 1
) else (
    echo %GREEN%Setup completed successfully without requiring admin rights.%RESET%
    echo.
    echo %YELLOW%Installed locations in your home directory:%RESET%
    echo   Java  : %JAVA_INSTALL_DIR%
    echo   Maven : %MAVEN_INSTALL_DIR%
    echo.
    echo %YELLOW%Configured USER environment variables:%RESET%
    echo   JAVA_HOME=%JAVA_INSTALL_DIR%
    echo   MAVEN_HOME=%MAVEN_INSTALL_DIR%
    echo   PATH includes Java and Maven bin directories at user scope
    echo.
    echo %GREEN%IMPORTANT:%RESET%
    echo %YELLOW%Please close and reopen Command Prompt, PowerShell, Windows Terminal,%RESET%
    echo %YELLOW%or any IDE terminal so the PATH changes take effect in new sessions.%RESET%
    echo.
    echo %GREEN%After restarting your terminal, run:%RESET%
    echo   java --version
    echo   mvn --version
    echo.
    pause
    exit /b 0
)

@REM Made with Bob