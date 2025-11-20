luaDebugMode = true
local this = ""
local charCheck = ""
local prevCamZoom = 1
local prevCamControlled = false
local weExistin = false

local function instantZoomSet(zoom)
	setProperty('defaultCamZoom', zoom)
	setProperty('camGame.zoom', zoom)
end

function onCreatePost()
	if _G[charCheck..'Name'] ~= this or weExistin then return end
	prevCamZoom = getProperty('defaultCamZoom')
	prevCamControlled = getProperty('isCameraOnForcedPos')
	weExistin = true

	createInstance('tojoGrr', 'objects.Character', {0, 0, 'argument-tojofight'})
	setProperty('tojoGrr.x', getProperty('tojoGrr.positionArray[0]'))
	setProperty('tojoGrr.y', getProperty('tojoGrr.positionArray[1]'))
	addToGroup('dadGroup', 'tojoGrr')

	setProperty('tojoGrr.x', getProperty('tojoGrr.x') + 1000)
	instantZoomSet(0.7)
	cameraSetTarget('dad')
	setProperty('isCameraOnForcedPos', true)

	makeLuaSprite('mojoBG', nil, 0, 0)
	makeGraphic('mojoBG', 1, 1)
	scaleObject('mojoBG', (screenWidth / 2) * 2, screenHeight * 2)
	setScrollFactor('mojoBG', 0, 0)
	setProperty('mojoBG.color', FlxColor("#FF0176"))

	makeLuaSprite('tojoBG', nil, screenWidth * 2, 0)
	makeGraphic('tojoBG', 1, 1)
	scaleObject('tojoBG', (screenWidth / 2) * 2, screenHeight * 2)
	setScrollFactor('tojoBG', 0, 0)
	setProperty('tojoBG.color', FlxColor("#00FF6E"))

	addToGroup('gfGroup', 'mojoBG', getObjectOrder('blufiBG', 'gfGroup'))
	addToGroup('gfGroup', 'tojoBG', getObjectOrder('blufiBG', 'gfGroup'))
	
	setProperty('mojoBG.y', getProperty('mojoBG.y') - (getProperty('mojoBG.height') / 2))
	setProperty('tojoBG.y', getProperty('tojoBG.y') - (getProperty('tojoBG.height') / 2))
	doTweenX('mojoBGAppear', 'mojoBG', (-screenWidth + 300) + (getProperty('mojoBG.width') / 2), 0.45, 'cubeOut')
	doTweenX('tojoBGAppear', 'tojoBG', ((-screenWidth + 300) + getProperty('mojoBG.width')) + (getProperty('tojoBG.width') / 2), 0.45, 'cubeOut')
end

function onCreate()
	this = runHaxeCode([[
		import haxe.io.Path;
		Path.withoutExtension(Path.withoutDirectory(script));
	]], {script = scriptName})

	charCheck = runHaxeCode([[
		var dads:Array<String> = [for (d in game.dadMap.keys()) d];
		var bfs:Array<String> = [for (b in game.boyfriendMap.keys()) b];
		var gfs:Array<String> = [for (g in game.gfMap.keys()) g];

		var char:String = "";
		for (attempt in [dads, bfs, gfs])
		{
			if (dads.contains(thisChar))
			{
				char = 'dad';
				break;
			}	
			
			if (bfs.contains(thisChar))
			{
				char = 'boyfriend';
				break;
			}

			if (gfs.contains(thisChar))
			{
				char = 'gf';
				break;
			}
		}
		char;
	]], {thisChar = this})

	addCharacterToList('argument-tojofight', "dad")
end

function onBeatHit()
	if not weExistin then return end

	if getProperty('tojoGrr') and curBeat % getProperty('tojoGrr.danceEveryNumBeats') == 0 and not stringStartsWith(callMethod('tojoGrr.getAnimationName'), 'sing') and not getProperty('tojoGrr.stunned') then
		callMethod('tojoGrr.dance')
	end
end

function opponentNoteHitPre(i, d, t)
	if t ~= 'Alt Animation' or (not getProperty('tojoGrr') or not weExistin) then return end
	setPropertyFromGroup('notes', i, 'noAnimation', true)

	playAnim('tojoGrr', getProperty('singAnimations['..d..']'), true)
	setProperty('tojoGrr.holdTimer', 0)
end

function onDestroy()
	removeLuaSprite('tojoGrr', true, 'dadGroup')
	removeLuaSprite('mojoBG', true, 'gfGroup')
	removeLuaSprite('tojoBG', true, 'gfGroup')

	setProperty('defaultCamZoom', prevCamZoom)
	setProperty('isCameraOnForcedPos', prevCamControlled)
	close()
end

local function tagFromNumV1(v1)
	if tonumber(v1) == nil then return 'boyfriend' end

	local tag = 'boyfriend'
	if tonumber(v1) == 2 then
		tag = 'gf'
	elseif tonumber(v1) == 1 then
		tag = 'dad'
	end
	return tag
end

function onEvent(n)
	if n ~= 'Change Character' then return end

	local changedCharCheck = 'boyfriend'
	if v1 == 'gf' or v1 == 'girlfriend' then
		changedCharCheck = 'gf'
	elseif v1 == 'dad' or v1 == 'opponent' then
		changedCharCheck = 'dad'
	else
		changedCharCheck = tagFromNumV1(v1)
	end
	
	if _G[charCheck..'Name'] == this then
		onCreatePost()
	elseif weExistin and changedCharCheck == charCheck then
		onDestroy()
	end
end