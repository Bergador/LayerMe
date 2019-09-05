--- HELPER FUNCTIONS

if LayerMeSettings == nil then LayerMeSettings = { x=0, y=0 }; end;

-- I hate having to write this function so very much
function NormalizeName(name)
    if not string.find(name, "-") then
        name = name .. "-" .. GetRealmName();
    end
    return name;
end

-- Credit to Mikk @ wowwiki.fandom.com
-- function StringHash(text)
    -- local counter = 1
    -- local len = string.len(text)
    -- for i = 1, len, 3 do 
        -- counter = math.fmod(counter*8161, 4294967279) +  -- 2^32 - 17: Prime!
        -- (string.byte(text,i)*16776193) +
        -- ((string.byte(text,i+1) or (len-i+256))*8372226) +
        -- ((string.byte(text,i+2) or (len-i+256))*3932164)
    -- end
    -- return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
-- end

---

--[[ TODO
- DISREGARD CONTINENTS
X keep internal list of registered people
X remove people from registered list if they log out
X invite in order of hash
X actual invite functionality + make other guy leader and leave
X send current layer with LayerMe request + update current layer on group join
X Update layer id when you join someone elses group
X grey button out when grouped 
X auto accept invite from player determined to be responsible for inviting you
X remember old layer and send with

- whisper people not to use guild chat
- remember button position after dragged
X send gchat message if noone is available to layer
X check for offliners
X remove or correct number display on button

- update own layer when invited to other group

]]--

-- local realmName = GetRealmName();

local LayerMeFrame = CreateFrame("Frame", "LayerMeFrame", UIParent);

-- LayerMeFrame:Show();

LayerMeFrame.currentLayer = NormalizeName(UnitName("player"));
LayerMeFrame.registered = {};
LayerMeFrame.invitee = nil;
LayerMeFrame.inviter = nil;


-- local LayerMeFrameButton = CreateFrame("Button", nil, LayerMeFrameButton, "GameMenuButtonTemplate");
local LayerMeFrameButton = CreateFrame("Button", nil, UIParent, "GameMenuButtonTemplate");
-- LayerMeFrameButton:SetPoint("CENTER", nil, UIParent, LayerMeSettings.x, LayerMeSettings.x)
LayerMeFrameButton:SetPoint("CENTER", LayerMeSettings.x, LayerMeSettings.y)
LayerMeFrameButton:SetWidth(100)
LayerMeFrameButton:SetHeight(30)
-- LayerMeFrameButton:SetText("LayerMe ("..#LayerMeFrame.registered..")")
LayerMeFrameButton:SetText("LayerMe")
LayerMeFrameButton:Show();
LayerMeFrameButton.isMoving = false;

LayerMeFrameButton:SetMovable(true)
LayerMeFrameButton:EnableMouse(true)
LayerMeFrameButton:SetClampedToScreen(true)
LayerMeFrameButton:RegisterForDrag("LeftButton")

LayerMeFrameButton:SetScript("OnClick", function(this, button)
    if not this.isMoving and not IsShiftKeyDown() then
        -- if button ~= "LeftButton" then
            -- C_ChatInfo.SendAddonMessage("LayerMe", "Broadcast", "GUILD");
            -- ChatFrame1:AddMessage("Sending Broadcast");
        -- end
        
        RequestNewLayer();
    end
end)

LayerMeFrameButton:SetScript("OnMouseDown", function(this, button)
    if IsShiftKeyDown() then
        if button == "LeftButton" and not this.isMoving then
            this:StartMoving();
            this.isMoving = true;
        end
    end
end)

LayerMeFrameButton:SetScript("OnMouseUp", function(this, button)
    if button == "LeftButton" and this.isMoving then
        this:StopMovingOrSizing();
        this.isMoving = false;
        local x, y = this:GetCenter()
        local ux, uy = UIParent:GetCenter()
        LayerMeSettings.x, LayerMeSettings.y = floor(x - ux + 0.5), floor(y - uy + 0.5)
    end
end)


LayerMeFrameButton:SetScript("OnEnter", function(this)
    -- GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
    -- local txt = "";
    -- for i=1,#LayerMeFrame.registered do
        -- if LayerMeFrame.registered[i] ~= NormalizeName(UnitName("player")) then
            -- txt = txt..LayerMeFrame.registered[i];
            -- if i < #LayerMeFrame.registered then
                -- txt = txt.."\n";
            -- end
        -- end
    -- end
    -- GameTooltip:SetText(txt);
end);

LayerMeFrameButton:SetScript("OnLeave", function()
    GameTooltip:Hide();
end);

LayerMeFrame:RegisterEvent("VARIABLES_LOADED");
LayerMeFrame:RegisterEvent("CHAT_MSG_GUILD");
LayerMeFrame:RegisterEvent("CHAT_MSG_ADDON");
LayerMeFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
LayerMeFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
LayerMeFrame:RegisterEvent("GUILD_ROSTER_UPDATE");
LayerMeFrame:RegisterEvent("PARTY_INVITE_REQUEST");
-- LayerMeFrame:RegisterEvent("GROUP_ROSTER_CHANGED");
-- LayerMeFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");

function RequestNewLayer()
    -- ChatFrame1:AddMessage("LayerMe request sent");
    C_ChatInfo.SendAddonMessage("LayerMe", "Request "..LayerMeFrame.currentLayer, "GUILD");
end

C_ChatInfo.RegisterAddonMessagePrefix("LayerMe")

function LayerMe_Register(name)
    -- ChatFrame1:AddMessage("Registering "..name.."");
    
    -- table.insert(LayerMeFrame.registered, name);
    
    -- I hate lua so very much
    local found = false;
    
    for i=1,#LayerMeFrame.registered do
        if LayerMeFrame.registered[i] == name then
            found = true
            break
        end
    end
    if not found then
        table.insert(LayerMeFrame.registered, name);
    end
    
    -- ChatFrame1:AddMessage(#LayerMeFrame.registered.." players in table now.");
    -- LayerMeFrameButton:SetText("LayerMe ("..#LayerMeFrame.registered..")")
end

function LayerMe_Unregister(name)
    -- ChatFrame1:AddMessage("Unregistering "..name.."");
    
    -- I hate lua so very much
    for i=1,#LayerMeFrame.registered do
        if LayerMeFrame.registered[i] == name then
            table.remove(LayerMeFrame.registered, i);
            break
        end
    end
    
    -- ChatFrame1:AddMessage(#LayerMeFrame.registered.." players in table now.");
    -- LayerMeFrameButton:SetText("LayerMe ("..#LayerMeFrame.registered..")")
end

function GuildieIsOnline(guildieName)
    for i=1,GetNumGuildMembers() do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i);
        -- fuck you blizzard
        name = NormalizeName(name);
        
        -- I hate lua so very much
        if name == guildieName then
            return online;
        end
    end
    return false;
end

function LayerMe_CheckForOffliners()

    local nbefore = #LayerMeFrame.registered;

    -- ChatFrame1:AddMessage("Cleaning registered players of offliners");
    
    for i=1,GetNumGuildMembers() do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i);
        -- fuck you blizzard
        name = NormalizeName(name);
        
        -- I hate lua so very much
        for j=1,#LayerMeFrame.registered do
            if LayerMeFrame.registered[j] == name then
                if not online then
                    -- ChatFrame1:AddMessage(name.." went offline.");
                    LayerMe_Unregister(name);
                end
            end
        end        
    end
    
    local nafter = #LayerMeFrame.registered;
    
    if nbefore ~= nafter then
        -- ChatFrame1:AddMessage(#LayerMeFrame.registered.." players in table now.");
        -- LayerMeFrameButton:SetText("LayerMe ("..#LayerMeFrame.registered..")")
    end
end

function LayerMe_DetermineInviter(requester, layer)
    -- ChatFrame1:AddMessage("Attempting to determine who is responsible for inviting "..requester..".");
        
    table.sort(LayerMeFrame.registered, function(a,b)
        return a > b
    end)

    -- ChatFrame1:AddMessage(#LayerMeFrame.registered.." in registered players table.");

    local inviter = nil;
    
    if #LayerMeFrame.registered > 0 then

        -- first guy in alphabetical order after requester
        for i=1,#LayerMeFrame.registered do
            if LayerMeFrame.registered[i] > layer and LayerMeFrame.registered[i] ~= requester then
                if GuildieIsOnline(LayerMeFrame.registered[i]) then
                    inviter = LayerMeFrame.registered[i];
                    break;
                end
            end
        end
        
        -- just make it anybody else
        if inviter == nil then
            -- inviter = LayerMeFrame.registered[1];
            for i=1,#LayerMeFrame.registered do
                if LayerMeFrame.registered[i] ~= layer and LayerMeFrame.registered[i] ~= requester then
                    if GuildieIsOnline(LayerMeFrame.registered[i]) then
                        inviter = LayerMeFrame.registered[i];
                        break;
                    end
                end
            end
        end
        
        if inviter == nil then
            inviter = "NOONE";
        end
    else
        inviter = "NOONE";
    end
    
    -- ChatFrame1:AddMessage(inviter.." is responsible for inviting player "..requester..".");
    
    return inviter;

end

LayerMeFrame:SetScript("OnEvent", function(this, event, arg1, arg2, arg3, arg4)

    if event == "CHAT_MSG_GUILD" then

        local message = strlower(arg1);
        local author = NormalizeName(arg2);
        local playerName = NormalizeName(UnitName("player"));
        
        if IsInGroup() then return end
        if author == playerName then return end;
                    
        if strfind(message, "layer") ~= nil and (strfind(message, "me") ~= nil or strfind(message, "inv") ~= nil or strfind(message, "pls") ~= nil or strfind(message, "plz") ~= nil or strfind(message, "please") ~= nil) then
        
            -- local myContinent = GetContinent(playerName);
            -- local theirContinent = GetContinent(author);
            
            -- if theirContinent ~= -1 and  theirContinent == myContinent then
                -- LayerThisGuy(author);
            -- end
            
            if string.find(message, "<LayerMe>") == nil then
                -- ChatFrame1:AddMessage(author.." asked for new layer the old fashioned way - make him stop!", 1,0,0);
                SendChatMessage("<LayerMe> please get the latest version of this addon from  https://github.com/Bergador/LayerMe - there is no need to spam guild chat anymore.", "WHISPER", nil, author);
            end            
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- ChatFrame1:AddMessage(event);
        
        if IsInGroup() then
            LayerMeFrameButton:Disable();
            C_ChatInfo.SendAddonMessage("LayerMe", "Unregister", "GUILD");
            
            if GetNumGroupMembers() == 2 then
                if LayerMeFrame.invitee ~= nil then
                    if NormalizeName(UnitName("party1")) == LayerMeFrame.invitee then
                        if UnitIsGroupLeader("player") then
                            PromoteToLeader("party1");
                        else
                            LeaveParty();
                        end
                    end
                end
            end            
        else
            LayerMeFrame.invitee = nil;
            LayerMeFrameButton:Enable();
            C_ChatInfo.SendAddonMessage("LayerMe", "Register", "GUILD");
        end
        
        -- make other guy leader and leave if he was invited via this addon
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- IF NTO GROUPED register to receive layering requests
        if not IsInGroup() then
            LayerMeFrameButton:Enable();
            C_ChatInfo.SendAddonMessage("LayerMe", "Register", "GUILD");
            C_ChatInfo.SendAddonMessage("LayerMe", "Broadcast", "GUILD");
        else
            LayerMeFrameButton:Disable();
        end
        
    elseif event == "CHAT_MSG_ADDON" then
        local prefix = arg1;
        local message = arg2;
        local channel = arg3;
        local sender = NormalizeName(arg4);
        local playerName = NormalizeName(UnitName("player"));
        
        if prefix == "LayerMe" then
           -- sender ~= playerName then
           
            -- ChatFrame1:AddMessage("LayerMe \""..message.."\" received from "..sender..".");
            
            if string.find(message, "Register") then
                local _, layer = strsplit(" ", message);
                
                LayerMe_Register(sender, layer);
                
            elseif string.find(message, "Unregister") then
                LayerMe_Unregister(sender);
            elseif string.find(message, "Broadcast") then
                if not IsInGroup() then
                    C_ChatInfo.SendAddonMessage("LayerMe", "Register "..LayerMeFrame.currentLayer, "GUILD");
                end
            elseif string.find(message, "Request") then
                -- C_ChatInfo.SendAddonMessage("LayerMe", "Request "..LayerMeFrame.currentLayer, "GUILD");
                
                local _, layer = strsplit(" ", message);                

                local inviter = LayerMe_DetermineInviter(sender, layer);

                if inviter == "NOONE" or inviter == nil then
                    SendChatMessage("<LayerMe> layer me please", "GUILD");  -- fallback
                else                     
                    -- ChatFrame1:AddMessage(inviter.." is responsible for inviting "..sender..".");
                    
                    if inviter == playerName then
                        -- ChatFrame1:AddMessage("Inviting "..sender..".");

                        LayerMeFrame.invitee = sender;
                        InviteUnit(sender);
                    elseif sender == playerName then
                        LayerMeFrame.inviter = inviter;
                    end
                end
            end
        end
    elseif event == "GUILD_ROSTER_UPDATE" then
        -- LayerMe_CheckForOffliners();
        
    elseif event == "PARTY_INVITE_REQUEST" then
        local inviter = NormalizeName(arg1);

        if LayerMeFrame.inviter ~= nil and inviter == LayerMeFrame.inviter then
            AcceptGroup();
            LayerMeFrame.inviter = nil;
            LayerMeFrame.currentLayer = inviter;
            
            for i=1, STATICPOPUP_NUMDIALOGS do
                if _G["StaticPopup"..i].which == "PARTY_INVITE" then
                    _G["StaticPopup"..i].inviteAccepted = 1
                    StaticPopup_Hide("PARTY_INVITE");
                    break
                elseif _G["StaticPopup"..i].which == "PARTY_INVITE_XREALM" then
                    _G["StaticPopup"..i].inviteAccepted = 1
                    StaticPopup_Hide("PARTY_INVITE_XREALM");
                    break
                end
            end
            return
        end
    elseif event == "VARIABLES_LOADED" then
            LayerMeFrameButton:SetPoint("CENTER", LayerMeSettings.x, LayerMeSettings.y);
    else
        -- ChatFrame1:AddMessage(event);
    end
end);



---

-- add delay
-- auto leave on group join if that guy was invited by this script
-- give leader prior to joining
-- react to whispers

local InvitesSent = {};
local InvitesAccepted = {};

function ShouldIInviteThisGuy()

end

function LayerThisGuy(name)
    -- ChatFrame1:AddMessage("<LayerMe> Inviting "..name.." to your layer.", 1, 1, 0);
    InviteUnit(name);
    table.insert(InvitesSent, {name=name, time=GetTime()});
end

function GetContinent(guild_member_name)

    -- ChatFrame1:AddMessage(guild_member_name);

    local theirZone = nil;

    for i=1,GetNumGuildMembers() do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i);
        
        -- ChatFrame1:AddMessage(name.." "..zone);
        
        if name == guild_member_name then
            -- ChatFrame1:AddMessage(zone);
            theirZone = zone
            break
        end
    end
    
    if theirZone == nil then
        -- ChatFrame1:AddMessage("player "..guild_member_name.." found in roster");
        return -1;
    else
        -- 1 = Kalimdor
        -- 2 = EPL
        local zones1 = {"Ashenvale", "Azshara", "Darkshore", "Darnassus", "Desolace", "Durotar", "Dustwallow Marsh", "Felwood", "Feralas", "Moonglade", "Mulgore", "Orgrimmar", "Silithus", "Stonetalon Mountains", "Tanaris", "Teldrassil", "The Barrens", "Thousand Needle", "Thunder Bluff", "Un'Goro Crater", "Winterspring" };
        
        local zones2 = {"Alterac Mountains", "Arathi Highlands", "Badlands", "Blasted Lands", "Burning Steppes", "Deadwind Pass", "Deeprun Tram", "Dun Morogh", "Duskwood", "Eastern Plaguelands", "Elwynn Forest", "Hillsbrad Foothills", "Ironforge", "Loch Modan", "Redridge Mountains", "Searing Gorge", "Silverpine Forest", "Stormwind City", "Stranglethorn Vale", "Swamp of Sorrows", "The Hinterlands", "Tirisfal Glades", "Undercity", "Western Plaguelands", "Westfall", "Wetlands"}
        
        for _,z in pairs(zones1) do
            if z == theirZone then
                -- ChatFrame1:AddMessage(1);
                return 1;
            end
        end

        for _,z in pairs(zones2) do
            if z == theirZone then
                -- ChatFrame1:AddMessage(2);
                return 2;
            end
        end
    end
    -- ChatFrame1:AddMessage("cant determine in which continent that guy is");
    return -1;    
end

