#pragma once

#include <optional>

#include "mod/Config.h"

#include <pl/Mod.hpp>

namespace clange_me {

class ClangeMeMod {
  public:
    static ClangeMeMod &instance();

    ClangeMeMod();

    [[nodiscard]] ll::mod::NativeMod &getSelf() const { return mSelf; }

    bool load();
    bool enable();
    bool disable();
    bool unload();

  private:
    ll::mod::NativeMod &mSelf;
    ModConfig mConfig;
    std::optional<pl::config::ConfigFile<ModConfig>> mConfigFile;
};

} // namespace clange_me
