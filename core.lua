local addonName, addon = ...

addon.debug = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, name, ...)
    addon:Debug("OnEvent", event, ...)
    if event == "AUCTION_HOUSE_SHOW" then
        addon:HookAHFunctions()

        -- Should be a safe time to hook the crafting order frame
    elseif event == "CRAFTINGORDERS_SHOW_CUSTOMER" then
        addon:HookCraftingOrderFunctions()
        addon:SetCraftingOrdersFilter()
    elseif event == "ADDON_LOADED" and name == addonName then
        if AHFilterRestoreDB and not AHFilterRestoreDB.ah then
            AHFilterRestoreDB.ah = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS)
            AHFilterRestoreDB.craftingOrders = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS)
            -- Old version of the DB - migrate
            for k, v in pairs(AHFilterRestoreDB) do
                if k ~= "ah" and k ~= "craftingOrders" then
                    AHFilterRestoreDB.ah[k] = v
                    AHFilterRestoreDB[k] = nil
                end
            end
        else
            AHFilterRestoreDB = AHFilterRestoreDB or {
                ah = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS),
                craftingOrders = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS)
            }
        end
    end
end)

function addon:HookCraftingOrderFunctions()
    if self.craftingOrderHooked then return end
    -- OnMenuResponse is called when filters are updated.
    hooksecurefunc(ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown, "OnMenuResponse", function(...)
        self:Debug("FilterDropdown:OnMenuResponse", ...)
        AHFilterRestoreDB.craftingOrders = ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.filters
    end)
    -- Unlike AH we can do a simple hook for the reset button.
    ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.ResetButton:HookScript("OnClick",
        function(...)
            self:Debug("FilterDropdown:ResetButton:OnClick", ...)
            AHFilterRestoreDB.craftingOrders = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS)
        end)

    self.craftingOrderHooked = true
end

function addon:SetCraftingOrdersFilter()
    ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.filters = AHFilterRestoreDB and next(
            AHFilterRestoreDB) and next(AHFilterRestoreDB.craftingOrders) and AHFilterRestoreDB.craftingOrders or
        CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS);
    -- This will update the filter button to show reset if needed.
    ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown:OnMenuResponse()
end

function addon:HookAHFunctions()
    if self.auctionHouseHooked then return end
    -- Store the filter whenever it's updated
    hooksecurefunc(AuctionHouseFrame.SearchBar, "OnFilterToggled", function()
        self:Debug "OnFilterToggled:"
        local newFilter = AuctionHouseFrame.SearchBar.FilterButton:GetFilters()
        AHFilterRestoreDB.ah = newFilter
    end)

    -- Loading FilterButton calls Reset, e.g. entering the "Auction" tab, so we set our filter after that
    hooksecurefunc(AuctionHouseFrame.SearchBar.FilterButton, "Reset", function()
        self:Debug("FilterButton:Reset")
        addon:SetAHFilters()
    end)

    -- Since we set our filter after the normal reset, we must re-implement reset functionality
    AuctionHouseFrame.SearchBar.FilterButton.ClearFiltersButton:HookScript("OnClick",
        function()
            self:Debug("OnAHReset")
            addon:AHFilterButtonResetOnClick(AuctionHouseFrame.SearchBar.FilterButton)
            AHFilterRestoreDB.ah = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS)
        end)
    self.auctionHouseHooked = true
end

function addon:SetAHFilters()
    self:Debug("Updating AH filters")
    -- Replace with our filter if it exists, otherwise use the default.
    AuctionHouseFrame.SearchBar.FilterButton.filters = AHFilterRestoreDB and next(AHFilterRestoreDB) and
        next(AHFilterRestoreDB.ah) and
        AHFilterRestoreDB.ah or CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS);
    AuctionHouseFrame.SearchBar:UpdateClearFiltersButton()
end

-- Copy of original https://www.townlong-yak.com/framexml/live/Blizzard_AuctionHouseUI/Blizzard_AuctionHouseSearchBar.lua#72
---@diagnostic disable-next-line: redefined-local
function addon:AHFilterButtonResetOnClick(self)
    self.filters = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS);
    self.minLevel = 0;
    self.maxLevel = 0;
    self.ClearFiltersButton:Hide();
end

function addon:Debug(...)
    if not self.debug then return end
    print("|cff008888AHFilterRestore:|r", ...)
end
