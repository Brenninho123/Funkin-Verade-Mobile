luaDebugMode = true

function onCreate()
	for _, c in pairs({"t", "m"}) do precacheImage('transitions/tojoTchola-'..c) end
end

function onStepHit()
	if curStep == 596 or curStep == 648 or curStep == 688 or curStep == 1368 then
		cameraSetTarget('boyfriend')
	end

	if curStep == 588 or curStep == 657 or curStep == 680 or curStep == 825 or curStep == 1416 then
		cameraSetTarget('dad')
	end

	if curStep == 1336 and not flashingLights then
		cameraFlash('hud', 'white', 0.62, true)
	end
end

function onEvent(event, value1, value2, strumTime)
	if event ~= 'Lyrics' then return end

	if value1 == "Tchoooola," then
		makeLuaSprite('tojoSmug', 'transitions/tojoTchola-t', screenWidth)
		screenCenter('tojoSmug', "y")
		setObjectCamera('tojoSmug', 'hud')

		doTweenX('phraseSteal', 'tojoSmug', screenWidth - (getProperty('tojoSmug.width') / 1.1), 0.75, 'circOut')
		addLuaSprite('tojoSmug')
	elseif value1 == "Tchoooola,O" then
		makeLuaSprite('mojoAngy', 'transitions/tojoTchola-m', -screenWidth)
		screenCenter('mojoAngy', "y") setProperty('mojoAngy.y', getProperty('mojoAngy.y') - 24)
		setObjectCamera('mojoAngy', 'hud')

		doTweenX('WHATHEFU', 'mojoAngy', 0, 0.75, 'circOut')
		setObjectOrder('mojoAngy', getObjectOrder('tojoSmug') - 1)
	elseif value1 == "" then
		if not flashingLights then cameraFlash('hud', 'white', 0.62, true) end
		doTweenX('tojoChill', 'tojoSmug', screenWidth, 0.4, 'quartOut')
		doTweenX('mojoChill', 'mojoAngy', -screenWidth, 0.4, 'quartOut')
	end
end

function onTweenCompleted(tag)
	if tag == 'mojoChill' then
		removeLuaSprite('tojoChill')
		removeLuaSprite('mojoChill')
	end
end