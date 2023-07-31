//
//  configuration.h
//  emuThreeDS
//
//  Created by Antique on 18/6/2023.
//

#pragma once

#include <memory>
#include <string>

#include "common/settings.h"

class INIReader;

class Configuration {
    std::unique_ptr<INIReader> configuration;
    std::string configuration_loc;

    bool LoadINI(const std::string& default_contents = "", bool retry = true);
    void ReadValues();

public:
    Configuration();
    ~Configuration();

    void Reload();

private:
    /**
     * Applies a value read from the sdl2_config to a Setting.
     *
     * @param group The name of the INI group
     * @param setting The yuzu setting to modify
     */
    template <typename Type, bool ranged>
    void ReadSetting(const std::string& group, Settings::Setting<Type, ranged>& setting);
};
