local hscriptExists = false

function onCreatePost()
	local transEvents = runHaxeCode('return game.eventNotes.filter((f) -> f.event == "Transitions");')
	for _, event in pairs(transEvents) do
		precacheImage('transitions/'..event['value1'])
		if checkFileExists('sounds/transition_'..event['value1']..'.ogg') then precacheSound('transition_'..event['value1']) end
	end
end

function onEvent(n, v1, v2)
	if n ~= 'Transitions' then return end
	if luaSpriteExists('trans') then removeLuaSprite('trans') end

	makeAnimatedLuaSprite('trans', 'transitions/'..v1)
	addAnimationByPrefix('trans', 'anim', 'frame', 12, false)
	setGraphicSize('trans', screenWidth, screenHeight)
	screenCenter('trans')
	setObjectCamera('trans', 'hud')
	addLuaSprite('trans', true)

	playAnim('trans', 'anim')
	runHaxeCode([[
		import psychlua.LuaUtils;

		function removeLuaSprite(tag, destroy)
		{
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if (obj == null || obj.destroy == null) return;
			
			game.remove(obj, true);
			if (destroy)
			{
				game.variables.remove(tag);
				obj.destroy();
			}
		}

		var playedAnimation:Bool = false;
		game.variables['trans'].animation.onFinish.addOnce((_) -> playedAnimation = true);

		function destroyTrans()
		{
			if (!playedAnimation) return;

			removeLuaSprite('trans', true);
			playedAnimation = false;
		}

	]])
	hscriptExists = true

	if not checkFileExists('sounds/transition_'..v1..'.ogg') then return end
	playSound('transition_'..v1, tonumber(v2) or 1)
end

function onUpdatePost()
	if not hscriptExists then return end
	runHaxeFunction("destroyTrans")
end