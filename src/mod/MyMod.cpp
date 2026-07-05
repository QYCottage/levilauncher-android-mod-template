#include "mod/MyMod.h"

#include <filesystem>

#include <pl/Mod.hpp>

namespace clange_me {

ClangeMeMod &ClangeMeMod::instance() {
    static ClangeMeMod instance;
    return instance;
}

bool ClangeMeMod::load(pl::mod::ModContext &context) {
    context.logger().debug("Loading...");

    std::error_code ec;
    std::filesystem::create_directories(context.dataDir(), ec);
    if (ec) {
        context.logger().error("Failed to create data directory {}: {}", context.dataDir().string(),
                               ec.message());
        return false;
    }

    std::filesystem::create_directories(context.configDir(), ec);
    if (ec) {
        context.logger().error("Failed to create config directory {}: {}",
                               context.configDir().string(), ec.message());
        return false;
    }

    mConfigFile.emplace(ModConfig{}, context.configDir() / "config.json",
                        context.configDir() / "config.schema.json");
    if (!mConfigFile->load()) {
        context.logger().warn("Failed to load typed config");
        return false;
    }
    mConfig = mConfigFile->value();

    context.logger().info("Loaded {} from {}", context.name(), context.modRootPath().string());
    return true;
}

bool ClangeMeMod::enable(pl::mod::ModContext &context) {
    context.logger().debug("Enabling...");
    if (!mConfig.enabled) {
        context.logger().info("clange_me is disabled by config");
        return true;
    }

    context.logger().info("Config message: {}", mConfig.message);
    return true;
}

bool ClangeMeMod::disable(pl::mod::ModContext &context) {
    context.logger().debug("Disabling...");
    // Undo enable-time state here.
    return true;
}

bool ClangeMeMod::unload(pl::mod::ModContext &context) {
    context.logger().debug("Unloading...");
    // Release load-time resources here.
    mConfigFile.reset();
    return true;
}

} // namespace clange_me
