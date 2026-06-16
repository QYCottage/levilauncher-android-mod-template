param(
    [ValidateSet("arm64-v8a", "armeabi-v7a", "all")]
    [string]$Abi = "arm64-v8a",
    [string]$BuildRoot = "build",
    [string]$AndroidPlatform = "android-28",
    [string]$PreloaderRoot = $env:LEVI_PRELOADER_ROOT,
    [string]$NdkHome = "",
    [string]$Generator = "Ninja"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")

function Invoke-ConfigGeneration {
    $configBuildDir = Join-Path $repoRoot "$BuildRoot-config"
    $preloaderArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($PreloaderRoot)) {
        $preloaderArgs += "-DLEVI_PRELOADER_ROOT=$PreloaderRoot"
    }

    & cmake -S $repoRoot -B $configBuildDir -G $Generator `
        @preloaderArgs 2>&1 |
        ForEach-Object { Write-Host $_ }

    & cmake --build $configBuildDir --target levi_generate_config 2>&1 |
        ForEach-Object { Write-Host $_ }

    return ((Resolve-Path (Join-Path $configBuildDir "generated-config")).Path -replace "\\", "/")
}

function Resolve-NdkHome {
    if (-not [string]::IsNullOrWhiteSpace($NdkHome) -and (Test-Path $NdkHome)) {
        return (Resolve-Path $NdkHome).Path
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
        $preferredNdk = Join-Path $env:ANDROID_HOME "ndk/28.2.13676358"
        if (Test-Path $preferredNdk) {
            return (Resolve-Path $preferredNdk).Path
        }

        $ndkRoot = Join-Path $env:ANDROID_HOME "ndk"
        if (Test-Path $ndkRoot) {
            $candidate = Get-ChildItem -Path $ndkRoot -Directory |
                Sort-Object Name -Descending |
                Select-Object -First 1
            if ($candidate) {
                return $candidate.FullName
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_NDK_HOME) -and (Test-Path $env:ANDROID_NDK_HOME)) {
        return (Resolve-Path $env:ANDROID_NDK_HOME).Path
    }

    throw "Android NDK not found. Set ANDROID_NDK_HOME or ANDROID_HOME."
}

function Invoke-ModBuild {
    param([string]$TargetAbi)

    $ndkHome = Resolve-NdkHome
    $toolchain = Join-Path $ndkHome "build/cmake/android.toolchain.cmake"
    $buildDir = Join-Path $repoRoot "$BuildRoot-$TargetAbi"
    $generatedConfigDir = Invoke-ConfigGeneration
    $preloaderArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($PreloaderRoot)) {
        $preloaderArgs += "-DLEVI_PRELOADER_ROOT=$PreloaderRoot"
    }

    cmake -S $repoRoot -B $buildDir -G $Generator `
        -DCMAKE_TOOLCHAIN_FILE="$toolchain" `
        -DANDROID_ABI="$TargetAbi" `
        -DANDROID_PLATFORM="$AndroidPlatform" `
        -DANDROID_STL="c++_shared" `
        @preloaderArgs `
        -DLEVI_PACKAGE_CONFIG_DIR="$generatedConfigDir"

    cmake --build $buildDir --target levi_package
}

if ($Abi -eq "all") {
    Invoke-ModBuild "arm64-v8a"
    Invoke-ModBuild "armeabi-v7a"
} else {
    Invoke-ModBuild $Abi
}
