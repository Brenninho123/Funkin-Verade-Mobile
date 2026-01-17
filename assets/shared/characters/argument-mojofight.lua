local this = ""
local charCheck = ""
local prevCamZoom = 1
local prevCamControlled = false
local weExistin = false
local prevX = 0

local function instantZoomSet(zoom)
	setProperty('defaultCamZoom', zoom)
	setProperty('camGame.zoom', zoom)
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

function onCreatePost()
	if weExistin or _G[charCheck..'Name'] ~= this then return end
	weExistin = true
	prevCamZoom = getProperty('defaultCamZoom')
	prevCamControlled = getProperty('isCameraOnForcedPos')
	prevX = getProperty(charCheck..'.x')

	createInstance('tojoGrr', 'objects.Character', {0, 0, 'argument-tojofight'})
	setProperty('tojoGrr.x', getProperty('tojoGrr.positionArray[0]'))
	setProperty('tojoGrr.y', getProperty('tojoGrr.positionArray[1]'))
	addToGroup('dadGroup', 'tojoGrr')

	local tojoX = getProperty('tojoGrr.x') + 1000
	setProperty('tojoGrr.x', screenWidth * 2)
	setProperty(charCheck..'.x', -screenWidth * 2)

	instantZoomSet(0.7)
	setProperty('camFollow.x', 935) callMethod('camGame.snapToTarget', {})
	setProperty('isCameraOnForcedPos', true)
	doTweenY('doCamMiddle', "camFollow", 680, 0.35, 'quartOut')

	makeLuaSprite('mojoBG', nil, -screenWidth * 2, 0)
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
	doTweenX('mojoAppear', charCheck, prevX, 0.4, 'cubeOut')
	doTweenX('tojoAppear', 'tojoGrr', tojoX, 0.4, 'cubeOut')
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

function onTweenCompleted(tag)
	if tag == 'mojoBGDisappear' then removeLuaSprite('mojoBG', true, 'gfGroup') end
	if tag == 'tojoBGDisappear' then removeLuaSprite('tojoBG', true, 'gfGroup') end
end

function onDestroy()
	if not weExistin then return end

	removeLuaSprite('tojoGrr', true, 'dadGroup')
	doTweenX('mojoBGDisappear', 'mojoBG', -screenWidth * 2, 0.45, 'cubeOut')
	doTweenX('tojoBGDisappear', 'tojoBG', screenWidth * 2, 0.45, 'cubeOut')

	setProperty('defaultCamZoom', prevCamZoom)
	setProperty('isCameraOnForcedPos', prevCamControlled)
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

function onEvent(n, v1)
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
	elseif changedCharCheck == charCheck then
		onDestroy()
	end
end