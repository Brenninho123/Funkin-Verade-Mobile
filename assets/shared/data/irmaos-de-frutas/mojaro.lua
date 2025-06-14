char = 'mojaro'
x = -600
y = 170
isPlayer = false
inFront = true
luaDebugMode = true
icon = '' -- dont override this

function onCreate()
	callextra(char, x, y, isPlayer, inFront)
	setProperty('extra.alpha', 0.0001)
end

function callextra(newChar, offsetX, offsetY, isPlayer, inFront)
	if newChar ~= char then
		char = newChar
	end
	local grp = isPlayer and 'boyfriend' or 'dad'

	createInstance('extra', 'objects.Character', {0, 0, newChar, isPlayer})
	callMethod('startCharacterPos', {instanceArg('extra'), false})
	callMethod(grp..'Group.add', {instanceArg('extra')})
	setOnScripts('extra', instanceArg('extra'))
	icon = 'iconP'..(isPlayer and '1' or '2')

	callMethod('extra.setPosition', {offsetX, offsetY})
end

function onBeatHit()
	if (stringStartsWith(getProperty('extra.animation.name'), 'sing') or curBeat % getProperty('extra.danceEveryNumBeats') ~= 0) or getProperty('extra.alpha') < 0.2 then
		return
	end
	
	callMethod('extra.dance')
end

function opponentNoteHitPre(i, d, t, s)
	if t ~= 'GF Sing' or isPlayer then
		if not isPlayer and getProperty(icon..'.char') ~= getProperty('dad.healthIcon') then
			callMethod(icon..'.changeIcon', {getProperty('dad.healthIcon')})
			setHealthBarColors( rgbArrayToHex(getProperty('dad.healthColorArray')) )
		end
		return
	end
	setPropertyFromGroup('notes', i, 'noAnimation', true)

	extranotehit(i, d, t, s)
	callMethod(icon..'.changeIcon', {getProperty('extra.healthIcon')})
	setHealthBarColors( rgbArrayToHex(getProperty('extra.healthColorArray')) )
end
function goodNoteHitPre(i, d, t, s)
	if t ~= 'GF Sing' or not isPlayer then
		if isPlayer and getProperty(icon..'.char') ~= getProperty('boyfriend.healthIcon') then
			callMethod(icon..'.changeIcon', {getProperty('boyfriend.healthIcon')})
			setHealthBarColors(nil, rgbArrayToHex(getProperty('boyfriend.healthColorArray')) )
		end
		return
	end
	setPropertyFromGroup('notes', i, 'noAnimation', true)

	extranotehit(i, d, t, s)
	callMethod(icon..'.changeIcon', {getProperty('extra.healthIcon')})
	setHealthBarColors(nil, rgbArrayToHex(getProperty('extra.healthColorArray')) )
end

function noteMiss(i, d, t, s)
	if t ~= 'GF Sing' or (not isPlayer and not getProperty('extra.hasMissAnimations')) then
		return
	end

	callMethod('extra.playAnim', {getProperty('singAnimations')[d + 1]..'miss', true})
	setProperty('extra.holdTimer', 0)
end		

-- Cloned from opponentNoteHit
function extranotehit(i, d, t, s)
	local animToPlay = getProperty('singAnimations')[d + 1]
	local playAnim = true

	if s then
		local holdAnimStr = animToPlay..'-hold'
		if callMethod('extra.hasAnimation', {holdAnimStr}) then
			animToPlay = holdAnimStr
		end

		if callMethod('extra.getAnimationName') == holdAnimStr or callMethod('extra.getAnimationName') == holdAnimStr..'-loop' then
			playAnim = false
		end
	end

	if playAnim then
		callMethod('extra.playAnim', {getProperty('singAnimations')[d+1], true})
	end
	setProperty('extra.holdTimer', 0)
end

function onEvent(n, v1, v2)
	if n == 'Change Extra Character' then
		callMethod('extra.destroy')
		callMethod('remove', {instanceArg('extra')})
		callMethod('variables.remove', {'extra'})
		yourmom = stringSplit(v2, ",")
		isPlayer = yourmom[1]
		inFront = yourmom[2]
		callextra(v1, x, y, isPlayer, inFront)
	end

	if n == 'Play Extra Character Animation' then
		callMethod('extra.playAnim', {v1, true})
		setProperty('extra.specialAnim', true)
	end
end

function rgbArrayToHex(array)
	return string.format("#%x%x%x", array[1], array[2], array[3])
end