@echo off
REM Set Java home if not already set
SET JAVA_HOME=C:\Program Files\Java\jdk-21
SET PATH=%JAVA_HOME%\bin;%PATH%

REM Verify Java installation
java -version
if %ERRORLEVEL% NEQ 0 (
    echo Java is not installed or JAVA_HOME is incorrect.
    pause
    exit /b
)

REM Navigate to the directory containing the compiled Java class
cd /d C:\Users\sairam\OneDrive\Desktop\backup

REM Run the Java program with the full package name (if applicable)
java com.FileBackupWithStructure

REM Pause to view output
pause
