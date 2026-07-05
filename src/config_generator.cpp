#include "mod/Config.h"

#include <filesystem>
#include <fstream>
#include <iostream>

namespace {

bool writeJson(const std::filesystem::path &path, const nlohmann::json &value) {
    std::error_code ec;
    std::filesystem::create_directories(path.parent_path(), ec);
    if (ec) {
        std::cerr << "Failed to create " << path.parent_path() << ": " << ec.message() << '\n';
        return false;
    }

    std::ofstream stream(path, std::ios::binary | std::ios::trunc);
    if (!stream) {
        std::cerr << "Failed to open " << path << '\n';
        return false;
    }

    stream << value.dump(2) << '\n';
    return stream.good();
}

} // namespace

int main(int argc, char **argv) {
    if (argc != 2) {
        std::cerr << "Usage: levi_config_generator <output-config-dir>\n";
        return 2;
    }

    const std::filesystem::path outputDir = argv[1];
    if (!writeJson(outputDir / "config.json", clange_me::makeDefaultConfigJson()))
        return 1;
    if (!writeJson(outputDir / "config.schema.json", clange_me::makeConfigSchemaJson()))
        return 1;

    return 0;
}
