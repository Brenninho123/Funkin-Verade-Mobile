local function getPath(path)
	local currentLevel = getPropertyFromClass("backend.Paths", 'currentLevel')
	return currentLevel and callMethodFromClass("backend.Paths", 'getFolderPath', {path, currentLevel}) or callMethodFromClass("backend.Paths", 'getSharedPath', {})
end

local function precacheFolderImages(folder, allowGPU)
	allowGPU = allowGPU or true
	for _, f in pairs(directoryFileList( getPath(folder) )) do
		if string.find(f, ".png", 1, true) then precacheImage(string.gsub(folder, "images/", "")..string.gsub(f, ".png", ""), allowGPU) end
	end
end

function onCreate()
	makeLuaSprite('Fundo1', "Fundo1", -520, 0)
	setGraphicSize('Fundo1', (getProperty('Fundo1.width') + 1124) * 1.2, (getProperty('Fundo1.height') + 700) * 1.2)
	setScrollFactor('Fundo1', 0.9, 1)

	makeLuaSprite('Fundo2', "Fundo2", -560 ,-550)
	scaleObject('Fundo2', 1.3, 1.3)
	setScrollFactor('Fundo2', 0.8, 0.25)
	setProperty('Fundo2.antialiasing', false)

	makeLuaSprite('Fundo3', "Fundo3", -1760, -610)
	scaleObject('Fundo3', 1.9, 1.8)
	setScrollFactor('Fundo3', 0.8, 0.68)
	setProperty('Fundo3.antialiasing', false)

	addLuaSprite('Fundo1', false)
	addLuaSprite('Fundo2', true)
	addLuaSprite('Fundo3', true)
	precacheFolderImages("images/tojoBG/")
end

local cachedEvents = {}
local cachedEventV1s = {}
local cachedEventV2s = {}
local cachedEventTimes = {}
local curIndex = 1

local altTojoIdle = false

function onEvent(n, v1, v2, t)
	table.insert(cachedEvents, n)
	table.insert(cachedEventV1s, #cachedEventV1s + 1, v1)
	table.insert(cachedEventV2s, #cachedEventV2s + 1, v2)
	table.insert(cachedEventTimes, #cachedEventTimes + 1, t)
	runTimer(n..'_delayedCallback_'..t, 0.4)

	if n == 'Change Character' then
		setProperty('Fundo2.visible', not stringStartsWith(v2, 'argument'))
		setProperty('Fundo3.visible', not stringStartsWith(v2, 'argument'))
	end
end

function onStepHit()
	if curStep == 1335 then
		altTojoIdle = true
	end
end

function onTimerCompleted(tag, loops, loopsLeft)
	if not string.find(tag, '_delayedCallback_', 1, true) then return end
	local cachedEvent = cachedEvents[curIndex]
	local cachedEventV1 = cachedEventV1s[curIndex]
	local cachedEventV2 = cachedEventV2s[curIndex]
	local cachedEventTime = cachedEventTimes[curIndex]

	curIndex = curIndex + 1
	if luaDebugMode then
		debugPrint('event: '..cachedEvent..' at '..cachedEventTime)
		debugPrint('event.value1: '..cachedEventV1)
		debugPrint('event.value2: '..cachedEventV2)
	end

	if cachedEvent == 'Transitions' then
		if cachedEventV1 == 'stealAMic' then
			makeLuaSprite('tonho-irritado', nil, -1061, -150)
			runHaxeCode("getVar('tonho-irritado').frames = Paths.getMultiAtlas(['tojoBG/Torajo_modo_seriu', 'tojoBG/eviltorjo']);")
			addAnimationByPrefix('tonho-irritado', 'idle', 'idle0', 16, false)
			addAnimationByPrefix('tonho-irritado', 'idle-pissed', 'idleeviltorajo', 24, false)
			scaleObject('tonho-irritado', 0.42, 0.42)
			runHaxeCode([[
				using StringTools;
				var originalScaling:Array<Float> = [getVar('tonho-irritado').scale.x, getVar('tonho-irritado').scale.y];

				getVar('tonho-irritado').animation.onFrameChange.add((n, f, _) -> 
				{
					if (f != 0) return;

					if (n.endsWith('-pissed'))
						getVar('tonho-irritado').scale.set(originalScaling[0] + 0.09, originalScaling[1] + 0.09);
					else
						getVar('tonho-irritado').scale.set(originalScaling[0], originalScaling[1]);
					getVar('tonho-irritado').updateHitbox();
				});
			]])
			addOffset('tonho-irritado', 'idle-pissed', 24, 296)
			addToGroup('gfGroup', 'tonho-irritado', 0)
		else removeLuaSprite('tonho-irritado', true, 'gfGroup') end
	end
end

function onBeatHit()
	if not luaSpriteExists('tonho-irritado') or curBeat % 2 ~= 0 then return end
	playAnim('tonho-irritado', 'idle'..(altTojoIdle and '-pissed' or ""), true)
end