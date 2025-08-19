function onCreatePost()
	for _, event in pairs(getProperty('eventNotes')) do
		if event['event'] ~= 'Transitions' then return end

		precacheImage('transition_'..event['value1'])
		precacheSound('transition_'..event['value1'])
	end
end

function onEvent(event, value1, value2, strumTime)
	if event ~= 'Transitions' then return end
	if luaSpriteExists('trans') then removeLuaSprite('trans') end

	makeAnimatedLuaSprite('trans', 'transition_'..value1)
	addAnimationByPrefix('trans', 'anim', 'frame', 12, false)
	setGraphicSize('trans', screenWidth, screenHeight)
	setObjectCamera('trans', 'hud')
	screenCenter('trans')
	addLuaSprite('trans', true)

	playAnim('trans', 'anim')
	playSound('transition_'..value1, tonumber(value2) or 1)
end