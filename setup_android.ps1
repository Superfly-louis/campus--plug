$ErrorActionPreference = "Continue"
Write-Host "Installing OpenJDK 17..."
winget install Microsoft.OpenJDK.17 --scope machine --silent --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) {
    Write-Host "Trying user scope install..."
    winget install Microsoft.OpenJDK.17 --scope user --silent --accept-source-agreements --accept-package-agreements
}

Write-Host "Downloading Android Cmdline Tools..."
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
$cmdlineToolsPath = "$sdkPath\cmdline-tools"
$latestPath = "$cmdlineToolsPath\latest"
$zipPath = "$env:TEMP\cmdline-tools.zip"

if (-not (Test-Path "$latestPath\bin\sdkmanager.bat")) {
    New-Item -ItemType Directory -Force -Path $cmdlineToolsPath | Out-Null
    Invoke-WebRequest -Uri "https://dl.google.com/android/repository/commandlinetools-win-11479570_latest.zip" -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $cmdlineToolsPath -Force
    Rename-Item -Path "$cmdlineToolsPath\cmdline-tools" -NewName "latest"
}

$sdkmanager = "$latestPath\bin\sdkmanager.bat"

# find java
$jdkPath = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\OpenJDK*" -Directory | Select-Object -First 1
if (-not $jdkPath) {
    $jdkPath = Get-ChildItem -Path "C:\Program Files\Microsoft\jdk-17*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
}
if ($jdkPath) {
    $env:JAVA_HOME = $jdkPath.FullName
    $env:PATH = "$($jdkPath.FullName)\bin;" + $env:PATH
}

Write-Host "Installing components via sdkmanager..."
"y`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`n" | & $sdkmanager --licenses
& $sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

Write-Host "Configuring Flutter..."
flutter config --android-sdk $sdkPath
"y`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`n" | flutter doctor --android-licenses --suppress-analytics

Write-Host "Verifying flutter doctor..."
flutter doctor
