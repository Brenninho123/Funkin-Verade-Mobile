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
	precacheImage('Torajo_modo_seriu')
end

local cachedEvent = ""
local cachedEventV1 = ""
local cachedEventV2 = ""
local cachedEventTime = 0
function onEvent(n, v1, v2, t)
	runTimer(n..'_delayedCallback_'..t, 0.4)
	cachedEvent, cachedEventV1, cachedEventV2, cachedEventTime = n, v1, v2, t
end

function onTimerCompleted(tag, loops, loopsLeft)
	if tag ~= cachedEvent..'_delayedCallback_'..cachedEventTime then return end

	if cachedEvent == 'Transitions' then	
		if cachedEventV1 == 'stealAMic' then
			makeAnimatedLuaSprite('tonho-irritado', 'Torajo_modo_seriu', -1061, -150)
			addAnimationByPrefix('tonho-irritado', 'idle', 'idle', 16, false)
			scaleObject('tonho-irritado', 0.42, 0.42)
			addToGroup('gfGroup', 'tonho-irritado', 0)
		else removeLuaSprite('tonho-irritado', true, 'gfGroup') end
	end
end

function onBeatHit()
	if not luaSpriteExists('tonho-irritado') or curBeat % 2 ~= 0 then return end
	playAnim('tonho-irritado', 'idle', true)
end