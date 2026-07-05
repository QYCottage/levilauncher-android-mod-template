# LeviLauncher Android Mod Template

This is a CMake template for LeviLauncher Android native mods. It includes a
ready-to-use `manifest.json`, CMake project, minimal `ClangeMeMod`, packaging script,
typed config generation, and GitHub Actions workflow.

## Project Layout

```text
.
├── CMakeLists.txt
├── manifest.json.in
├── scripts/package.ps1
└── src
    ├── config_generator.cpp
    ├── main.cpp
    └── mod
        ├── Config.cpp
        ├── MyMod.cpp
        └── MyMod.h
```

## Requirements

- Android SDK
- Android NDK 28.2.13676358 or a compatible version
- CMake 3.22+
- Ninja
- PowerShell 7+, or Windows PowerShell

The CMake project fetches preloader-android from
<https://github.com/LiteLDev/preloader-android> automatically.

Set `LEVI_PRELOADER_ROOT`, pass `-DLEVI_PRELOADER_ROOT=<path>`, or use
`scripts/package.ps1 -PreloaderRoot <path>` only when you want to use a local
preloader-android checkout.

By default this template pins `LEVI_PRELOADER_GIT_TAG` to release `0.2.0`.
Move that value only after your mod has tested against the newer SDK release.

## Build

```powershell
$env:ANDROID_HOME = "C:/Users/<you>/AppData/Local/Android/Sdk"

./scripts/package.ps1 -Abi arm64-v8a
```

Build both Android architectures:

```powershell
./scripts/package.ps1 -Abi all
```

After the build finishes, import the generated `.levipack` into LeviLauncher.

## Customize Mod Info

Common CMake options:

```powershell
cmake -S . -B build-arm64-v8a `
  -G Ninja `
  -DCMAKE_TOOLCHAIN_FILE="$env:ANDROID_HOME/ndk/28.2.13676358/build/cmake/android.toolchain.cmake" `
  -DANDROID_ABI=arm64-v8a `
  -DANDROID_PLATFORM=android-28 `
  -DANDROID_STL=c++_shared `
  -DMOD_ID=clange_me `
  -DMOD_NAME="Clange Me Mod" `
  -DMOD_AUTHOR="clange_me" `
  -DMOD_VERSION=0.1.0 `
  -DMOD_LIBRARY_NAME=clange_me `
  -DMOD_MINECRAFT_VERSIONS='["1.21.*"]' `
  "-DMOD_ICON="

cmake --build build-arm64-v8a --target levi_package
```

## Lifecycle

Write your mod logic in [src/mod/MyMod.cpp](src/mod/MyMod.cpp):

```cpp
bool ClangeMeMod::load(pl::mod::ModContext &context) {
    context.logger().debug("Loading...");
    return true;
}

bool ClangeMeMod::enable(pl::mod::ModContext &context) {
    context.logger().debug("Enabling...");
    return true;
}

bool ClangeMeMod::disable(pl::mod::ModContext &context) {
    context.logger().debug("Disabling...");
    return true;
}

bool ClangeMeMod::unload(pl::mod::ModContext &context) {
    context.logger().debug("Unloading...");
    return true;
}
```

Lifecycle meaning:

1. `load()` runs when the mod is loaded.
2. `enable()` runs before the game starts.
3. `disable()` runs when the game is closing.
4. `unload()` runs during final mod cleanup.

Common APIs:

- `context.logger()`
- `context.id()`
- `context.name()`
- `context.modRootPath()`
- `context.dataDir()`
- `context.configDir()`
- `context.resourceDir()`
- `context.javaVm()`

Use `context.dataDir()` and `context.configDir()` for your mod's own data and config
files.

## Typed Config

The template includes a minimal typed config in `src/mod/MyMod.h`:

```cpp
struct ModConfig {
    int version = 1;
    bool enabled = true;
    std::string message = "Hello from clange_me";
};
```

`ClangeMeMod::load()` uses `pl::config::ConfigFile<ModConfig>` to create and update
`config/config.json`. The package script runs `src/config_generator.cpp` before
Android compilation and includes generated `config.json` and
`config.schema.json` in the `.levipack`.

Keep this config small for your starter mod. Move larger examples, advanced
schema coverage, or behavior tests into a separate project.
