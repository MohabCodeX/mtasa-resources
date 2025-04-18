g_ScreenX,g_ScreenY = guiGetScreenSize()
g_FragColor = tocolor(255,255,255,255)

local fragText,spreadText,rankText,respawnText,currentRank
--CONFIG
local fragWidth = 146
local fragHeight = 68
local fragTextScale = 2
local textScale = 1.5
local fragStartX = g_ScreenX - 20 - fragWidth
local fragStartY = g_ScreenY - 20 - fragHeight
----
----UTILITY FUNCS
local function sortingFunction (a,b)
	return (getElementData(a,"Score") or 0) > (getElementData(b,"Score") or 0)
end

local function dxSetYellowFrag ( dx, b )
	b = (b < 255) and (255 - b) or b
	g_FragColor = tocolor(255,255,b,255)
end
local function dxSetYellow ( dx, b )
	b = (b < 255) and (255 - b) or b
	dx:color(255,255,b,255)
end
local function dxSetAlpha ( dx, a )
	local r,g,b = dx:color()
	dx:color(r,g,b,a)
end
----

addEventHandler ( "onClientResourceStart", resourceRoot,
	function()
		respawnText = dxText:create( "", 0.5, 0.5, true, "pricedown", 2 )
		respawnText:type("stroke",1.2)
		respawnText:color ( 255,0,0, 0 )
		respawnText:visible(false)
		--
		fragText = dxText:create( "0", 0, 0, true, "pricedown", fragTextScale )
		fragText:type("stroke",fragTextScale)
		fragText:boundingBox(fragStartX + 65,fragStartY + 15,fragStartX + 131,fragStartY + fragHeight - 10, false)
		--
		spreadText = dxText:create( "Spread: 0", 0, 0, true, "Arial", textScale )
		spreadText:align("right","bottom")
		spreadText:type("shadow",2,2)
		spreadText:boundingBox(0,0,fragStartX + fragWidth - 20,fragStartY - 2, false)
		--
		rankText = dxText:create( "Rank:  -/-", 0, 0, true, "Arial", textScale )
		rankText:align("right","bottom")
		rankText:type("shadow",2,2)
		rankText:boundingBox(0,0,fragStartX + fragWidth - 20,fragStartY - 2 - dxGetFontHeight ( textScale, "Arial" ), false )
	end
)

addEventHandler ( "onClientRender", root,
	function()
		local team = getPlayerTeam(localPlayer)
		if team then
			local r,g,b = getTeamColor(team)
			dxDrawImage ( fragStartX, fragStartY, fragWidth, fragHeight, "images/frag.png", 0, 0, 0, tocolor(r,g,b,255) )
		end
	end
)

addEventHandler ( "onClientElementDataChange", root,
	function ( dataName )
		if dataName == "Score" then
			updateScores()
		end
	end
)

function updateScores()
	local localTeam = getPlayerTeam(localPlayer)
	if not localTeam or not isElement(localTeam) then return end
	local currentScore = getElementData(localTeam,"Score")
	fragText:text(tostring(currentScore))
	if source == localPlayer then
		if (currentScore < 0) then
			fragText:color(255,0,0,255)
		else
			fragText:color(255,255,255,255)
		end
		--Make the score smaller if the frag limit is 3 digits
		local length = #tostring(currentScore)
		if length >= 3 then
			fragText:scale(fragTextScale - ((length - fragTextScale)^0.7)*0.5)
		else
			fragText:scale(fragTextScale)
		end
		-- Animation.createAndPlay(
		  -- true,
		  -- {{ from = 510, to = 0, time = 400, fn = dxSetYellowFrag }}
		-- )
	end
	--Lets calculate local position
	local rank
	local teams = getElementsByType"team"
	table.sort ( teams, sortingFunction )
	for i,team in ipairs(teams ) do
		if team == localTeam then
			rank = i
			break
		end
	end
	--Quickly account for drawing positions
	for i=rank,1,-1 do
		if isElement ( teams[i] ) then
			if currentScore == getElementData ( teams [i], "Score" ) then
				rank = i
			else
				break
			end
		end
	end
	--Calculate spread
	local spreadTargetScore = (rank == 1) and
				getElementData ( teams [2] or teams [1], "Score" )
				or getElementData ( teams [1], "Score" ) or 0
	local spread = currentScore - spreadTargetScore
	spreadText:text("Spread: "..spread)
	if rank ~= currentRank then
		currentRank = rank
		rankText:text ( "Rank "..rank.."/"..#teams  )
		-- Animation.createAndPlay(
			-- rankText,
			-- {{ from = 0, to = 500, time = 600, fn = dxSetYellow }}
		-- )
	end
end
addEventHandler ( "onClientPlayerQuit", root, updateScores )
addEventHandler ( "onClientPlayerJoin", root, updateScores )

local countdownCR
local function countdown(time)
	for i=time,0,-1 do
		respawnText:text("You will respawn in "..i.." seconds")
		setTimer ( countdownCR, 1000, 1 )
		coroutine.yield()
	end
end

local function hideCountdown()
	setTimer (
		function()
			respawnText:visible(false)
		end,
		600, 1
	)
	Animation.createAndPlay(
	  respawnText,
	  {{ from = 255, to = 0, time = 400, fn = dxSetAlpha }}
	)
	removeEventHandler ( "onClientPlayerSpawn", localPlayer, hideCountdown )
end

addEvent ( "requestCountdown", true )
addEventHandler ( "requestCountdown", root,
	function(time)
		Animation.createAndPlay(
		  respawnText,
		  {{ from = 0, to = 255, time = 600, fn = dxSetAlpha }}
		)
		addEventHandler ( "onClientPlayerSpawn", localPlayer, hideCountdown )
		respawnText:visible(true)
		time = math.floor(time/1000)
		countdownCR = coroutine.wrap(countdown)
		countdownCR(time)
	end
)

addEvent ( "onColtPickup", true )
addEventHandler ( "onColtPickup", root,
	function()
		if getPedWeapon ( source, 2 ) == 22 and getPedTotalAmmo ( source, 2 ) ~= 0 then
			triggerServerEvent ( "doSetColtStat", localPlayer, true )
		elseif getPedStat ( source, 69 ) >= 999 then
			triggerServerEvent ( "doSetColtStat", localPlayer, false )
		end
	end
)

-- Add these variables for client-side state preservation
local preservedClientState = {}

-- Create events for preserving and restoring client state
addEvent("tdm:preserveClientState", true)
addEventHandler("tdm:preserveClientState", localPlayer,
    function()
        -- Save camera state
        local cx, cy, cz, tx, ty, tz = getCameraMatrix()
        preservedClientState.camera = {
            position = {cx, cy, cz},
            target = {tx, ty, tz}
        }

        -- Save HUD state
        preservedClientState.hud = {}
        local hudComponents = {"ammo", "area_name", "armour", "breath", "clock",
                              "health", "money", "radar", "vehicle_name", "weapon"}
        for _, component in ipairs(hudComponents) do
            preservedClientState.hud[component] = isHudComponentVisible(component)
        end

        -- Save other client-specific states
        preservedClientState.blurLevel = getBlurLevel()
        preservedClientState.skyGradient = {getSkyGradient()}

        -- Save sound states
        preservedClientState.sound = {
            sfx = getSFXStatus(),
            radio = getRadioChannel()
        }

        triggerServerEvent("tdm:clientPreservationComplete", localPlayer)
    end
)

addEvent("tdm:restoreClientState", true)
addEventHandler("tdm:restoreClientState", localPlayer,
    function()
        -- Restore HUD
        if preservedClientState.hud then
            for component, visible in pairs(preservedClientState.hud) do
                setHudComponentVisible(component, visible)
            end
        end

        -- Reset camera fade
        fadeCamera(true, 1.0)

        -- Restore camera if we have valid data (but ensure player can see)
        if preservedClientState.camera then
            setCameraTarget(localPlayer)
            -- Optional: restore exact camera position
            -- setCameraMatrix(unpack(preservedClientState.camera.position), unpack(preservedClientState.camera.target))
        end

        -- Restore visual effects
        if preservedClientState.blurLevel then
            setBlurLevel(preservedClientState.blurLevel)
        end

        if preservedClientState.skyGradient and #preservedClientState.skyGradient >= 6 then
            setSkyGradient(unpack(preservedClientState.skyGradient))
        end

        -- Restore sound settings
        if preservedClientState.sound then
            if preservedClientState.sound.sfx then
                setSFXStatus(preservedClientState.sound.sfx)
            end
            if preservedClientState.sound.radio then
                setRadioChannel(preservedClientState.sound.radio)
            end
        end

        -- Clear all UI elements
        if respawnText then respawnText:visible(false) end
        if fragText then fragText:visible(false) end
        if spreadText then spreadText:visible(false) end
        if rankText then rankText:visible(false) end

        preservedClientState = {}
    end
)

-- Enhance the resource stop handler
addEventHandler("onClientResourceStop", resourceRoot,
    function()
        -- Ensure camera is reset
        fadeCamera(true, 1.0)
        setCameraTarget(localPlayer)

        -- Hide all UI elements
        if respawnText then respawnText:visible(false) end
        if fragText then fragText:visible(false) end
        if spreadText then spreadText:visible(false) end
        if rankText then rankText:visible(false) end

        -- Make sure HUD is visible
        for _, component in ipairs({"ammo", "health", "weapon", "money", "breath", "armour", "clock", "radar"}) do
            setHudComponentVisible(component, true)
        end

        -- Clear post effects
        setBlurLevel(0)
        resetSkyGradient()

        -- Remove all GUI elements that might have been created
        for _, element in ipairs(getElementsByType("gui-text"), getElementsByType("gui-button"),
                                 getElementsByType("gui-window"), getElementsByType("gui-label")) do
            if isElement(element) then
                destroyElement(element)
            end
        end
    end
)
