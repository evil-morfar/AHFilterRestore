local addonName, addon = ...

addon.debug = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, name, ...)
    addon:Debug("OnEvent", event, ...)
    if event == "AUCTION_HOUSE_SHOW" then
        addon:SetupHooks()
    elseif event == "ADDON_LOADED" and name == addonName then
        AHFilterRestoreDB = AHFilterRestoreDB or {}
    end
end)

function addon:SetupHooks()
    if self.hooked then return end

    -- Store the filter whenver it's updated
    hooksecurefunc(AuctionHouseFrame.SearchBar, "OnFilterToggled", function()
        self:Debug "OnFilterToggled:"
        local newFilter = AuctionHouseFrame.SearchBar.FilterButton:GetFilters()
        AHFilterRestoreDB = newFilter
    end)

    -- Entering the "Auction" tab will cause a reset to fire, so we set our filter after that
    hooksecurefunc(AuctionHouseFrame.SearchBar.FilterButton, "Reset", function()
        self:Debug("FilterButton:Reset")
        addon:UpdateFilters()
    end)

    -- Since we set our filter after the normal reset, we must re-implement reset functionality
    AuctionHouseFrame.SearchBar.FilterButton.ClearFiltersButton:SetScript("OnClick",
        function()
            self:Debug("OnReset")
            addon:FilterButtonResetOnClick(AuctionHouseFrame.SearchBar.FilterButton)
            addon:Reset()
        end)

    self.hooked = true
end

function addon:UpdateFilters()
    self:Debug("Updating filters")
    -- Replace with our filter if it exists, otherwise use the default.
    AuctionHouseFrame.SearchBar.FilterButton.filters = next(AHFilterRestoreDB) and AHFilterRestoreDB or
        CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS);
    AuctionHouseFrame.SearchBar:UpdateClearFiltersButton()
end

-- Copy of original https://www.townlong-yak.com/framexml/live/Blizzard_AuctionHouseUI/Blizzard_AuctionHouseSearchBar.lua#72
---@diagnostic disable-next-line: redefined-local
function addon:FilterButtonResetOnClick(self)
    self.filters = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS);
    self.minLevel = 0;
    self.maxLevel = 0;
    self.ClearFiltersButton:Hide();
end

function addon:Reset()
    wipe(AHFilterRestoreDB)
end

function addon:Debug(...)
    if not self.debug then return end
    print("|cff008888AHFilterRestore:|r", ...)
end
