//
//  game_info.cpp
//  emuThreeDS
//
//  Created by Antique on 15/6/2023.
//

#include "game_info.h"

#include "core/hle/service/am/am.h"
#include "core/hle/service/fs/archive.h"
#include "core/loader/loader.h"
#include "core/loader/smdh.h"

namespace GameInfo {
    std::vector<uint8_t> GetSMDHData(std::string physical_name) {
        std::unique_ptr<Loader::AppLoader> loader = Loader::GetLoader(physical_name);
        if (!loader) {
            return {};
        }

        uint64_t program_id = 0;
        loader->ReadProgramId(program_id);

        std::vector<uint8_t> smdh = [program_id, &loader]() -> std::vector<uint8_t> {
            std::vector<uint8_t> original_smdh;
            loader->ReadIcon(original_smdh);

            if (program_id < 0x00040000'00000000 || program_id > 0x00040000'FFFFFFFF)
                return original_smdh;

            std::string update_path = Service::AM::GetTitleContentPath(Service::FS::MediaType::SDMC, program_id + 0x0000000E'00000000);

            if (!FileUtil::Exists(update_path))
                return original_smdh;

            std::unique_ptr<Loader::AppLoader> update_loader = Loader::GetLoader(update_path);

            if (!update_loader)
                return original_smdh;

            std::vector<uint8_t> update_smdh;
            update_loader->ReadIcon(update_smdh);
            return update_smdh;
        }();

        return smdh;
    }
    
    
    std::vector<uint16_t> GetIcon(std::string physical_name) {
        std::vector<uint8_t> smdh_data = GetSMDHData(physical_name);

        if (!Loader::IsValidSMDH(smdh_data)) {
            // SMDH is not valid, return null
            return std::vector<uint16_t>(0, 0);
        }

        Loader::SMDH smdh;
        memcpy(&smdh, smdh_data.data(), sizeof(Loader::SMDH));

        // Always get a 48x48(large) icon
        std::vector<uint16_t> icon_data = smdh.GetIcon(true);
        return icon_data;
    }
    

    std::u16string GetPublisher(std::string physical_name) {
        Loader::SMDH::TitleLanguage language = Loader::SMDH::TitleLanguage::English;
        std::vector<uint8_t> smdh_data = GetSMDHData(physical_name);

        if (!Loader::IsValidSMDH(smdh_data)) {
            // SMDH is not valid, return null
            return {};
        }

        Loader::SMDH smdh;
        memcpy(&smdh, smdh_data.data(), sizeof(Loader::SMDH));

        // Get the Publisher's name from SMDH in UTF-16 format
        char16_t* publisher;
        publisher =
            reinterpret_cast<char16_t*>(smdh.titles[static_cast<int>(language)].publisher.data());

        return publisher;
    }
    
    std::string GetRegions(std::string physical_name) {
        std::vector<uint8_t> smdh_data = GetSMDHData(physical_name);

        if (!Loader::IsValidSMDH(smdh_data)) {
            // SMDH is not valid, return "Invalid region"
            return "Invalid region";
        }

        Loader::SMDH smdh;
        memcpy(&smdh, smdh_data.data(), sizeof(Loader::SMDH));

        using GameRegion = Loader::SMDH::GameRegion;
        static const std::map<GameRegion, const char*> regions_map = {
            {GameRegion::Japan, "Japan"},   {GameRegion::NorthAmerica, "North America"},
            {GameRegion::Europe, "Europe"}, {GameRegion::Australia, "Australia"},
            {GameRegion::China, "China"},   {GameRegion::Korea, "Korea"},
            {GameRegion::Taiwan, "Taiwan"}};
        std::vector<GameRegion> regions = smdh.GetRegions();

        if (regions.empty()) {
            return "Invalid region";
        }

        const bool region_free =
            std::all_of(regions_map.begin(), regions_map.end(), [&regions](const auto& it) {
                return std::find(regions.begin(), regions.end(), it.first) != regions.end();
            });

        if (region_free) {
            return "Region free";
        }

        const std::string separator = ", ";
        std::string result = regions_map.at(regions.front());
        for (auto region = ++regions.begin(); region != regions.end(); ++region) {
            result += separator + regions_map.at(*region);
        }

        return result;
    }
    
    std::u16string GetTitle(std::string physical_name) {
        Loader::SMDH::TitleLanguage language = Loader::SMDH::TitleLanguage::English;
        std::vector<uint8_t> smdh_data = GetSMDHData(physical_name);

        if (!Loader::IsValidSMDH(smdh_data)) {
            // SMDH is not valid, return null
            return {};
        }

        Loader::SMDH smdh;
        memcpy(&smdh, smdh_data.data(), sizeof(Loader::SMDH));

        // Get the title from SMDH in UTF-16 format
        std::u16string title{
            reinterpret_cast<char16_t*>(smdh.titles[static_cast<int>(language)].long_title.data())};

        return title;
    }
}
