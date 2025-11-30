tcholaMoment = false -- toggle this script
isPlayer = false
iconSpr = "" -- which original icon to do the swapping
icon = "" -- second char icon

customData = { -- preset for iconP3 to use rather than going from last character
	['icon'] = 'torajo-grr',
	['fruit'] = 'apple',
	['hpCol'] = {20, 209, 116},
	['fruitCol'] = {0, 244, 113}, -- fruit main col
	['fruitCol2'] = {220, 91, 235} -- fruit accent col
}
_lastIconPlayer = ""
_lastIcon = ""
_lastFruitPlayer = ""
_lastFruit = ""
_hpColorPlayer = {}
_hpColor = {}
_fruitColorPlayer = {}
_fruitColor = {}
_fruitAccentPlayer = {}
_fruitAccent = {}

local function rgbArrayToHex(array)
	return string.format("#%x%x%x", array[1], array[2], array[3])
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

function onCreate()
	runHaxeCode([[
		import Reflect;
		import objects.HealthIcon;

		var iconP3:HealthIcon = new HealthIcon(null, false, "");
		iconP3.charSprite.scale.set(0.65, 0.65); iconP3.charSprite.updateHitbox();
		iconP3.fruitSprite.scale.set(1.15, 1.15); iconP3.fruitSprite.updateHitbox();
		iconP3.fruitSprite.x += 22; iconP3.fruitSprite.y += 27;
		iconP3.setPosition(game.iconP2.x + 24, game.iconP2.y - 40);
		iconP3.visible = false;

		setVar('iconP3', iconP3);
		game.uiGroup.insert(game.uiGroup.members.indexOf(game.iconP2) - 1, iconP3);

		function setFruitColors(icon:String, customIcon:Bool, main:Array<Int>, accent:Array<Int>)
		{
			var icon:HealthIcon = customIcon ? getVar(icon) : Reflect.getProperty(game, icon);
			icon.fruitRGB.r = FlxColor.fromRGB(main[0], main[1], main[2]);
			icon.fruitRGB.b = FlxColor.fromRGB(accent[0], accent[1], accent[2]);
		}
	]])
end

function onCreatePost()
	if customData then
		for _, suffix in pairs({"", "player"}) do
			_G['_lastIcon'..suffix] = customData['icon']
			_G['_lastFruit'..suffix] = customData['fruit']

			_G['_hpColor'..suffix] = customData['hpCol']
			_G['_fruitColor'..suffix] = customData['fruitCol']
			_G['_fruitAccent'..suffix] = customData['fruitCol2']
		end
		return
	end

	_lastIconPlayer = getProperty('boyfriend.healthIcon')
	_hpColorPlayer = getProperty('boyfriend.healthColorArray')
	_lastIcon = getProperty('dad.healthIcon')
	_hpColor = getProperty('dad.healthColorArray')

	_lastFruitPlayer = getProperty('boyfriend.healthFruit')
	_lastFruit = getProperty('dad.healthFruit')

	_fruitAccentPlayer = getProperty('boyfriend.fruitAccentColor')
	_fruitAccent = getProperty('dad.fruitAccentColor')
	_fruitColorPlayer = getProperty('boyfriend.fruitColorArray')
	_fruitColor = getProperty('dad.fruitColorArray')
end

function opponentNoteHitPre(_, _, t, s)
	if s then return end
	local healthBar = (getPropertyFromClass("states.PlayState", 'stageUI') ~= 'legacy') and 'opponentHealthBar' or 'healthBar'

	doIconShi(isPlayer, t, 'dad', healthBar)
end
function goodNoteHitPre(_, _, t, s)
	if s then return end
	doIconShi((not isPlayer), t, 'boyfriend', 'healthBar')
end

function doIconShi(playerCheck, noteType, character, healthBar)
	if not tcholaMoment then return end
	local doIconSwap = getVar('paIconShi') or false

	if noteType ~= 'Alt Animation' or playerCheck then
		if not playerCheck then
			swapIcon(character, iconSpr, healthBar)
			if doIconSwap then
				swapIcon('extra', 'iconP3')
				callMethod('iconP3.changeFruit', {getProperty(character..'.healthFruit')})
				runHaxeFunction('setFruitColors', {'iconP3', true, getProperty(character..'.fruitColorArray'), getProperty(character..'.fruitAccentColor')})
			else
				callMethod(iconSpr..'.changeFruit', {getProperty(character..'.healthFruit')})
				runHaxeFunction('setFruitColors', {iconSpr, false, getProperty(character..'.fruitColorArray'), getProperty(character..'.fruitAccentColor')})
			end
		end
		return
	end

	swapIcon('extra', iconSpr, healthBar, true)
	if doIconSwap then
		swapIcon(character, 'iconP3', nil, true)
		callMethod('iconP3.changeFruit', {getProperty('extra.healthFruit')})
		runHaxeFunction('setFruitColors', {'iconP3', true, getProperty('extra.fruitColorArray'), getProperty('extra.fruitAccentColor')})
	else
		callMethod(iconSpr..'.changeFruit', {getProperty('extra.healthFruit')})
		runHaxeFunction('setFruitColors', {iconSpr, false, getProperty('extra.fruitColorArray'), getProperty('extra.fruitAccentColor')})
	end
end

function swapIcon(character, iconTag, healthBarTag, forced)
	forced = forced or false
	if not forced and getProperty(iconTag..'.char') == getProperty(character..'.healthIcon') then return end

	callMethod(iconTag..'.changeIcon', {getProperty(character..'.healthIcon')})
	if not healthBarTag then return end

	setProperty(healthBarTag..'.leftBar.color', FlxColor( rgbArrayToHex(getProperty(character..'.healthColorArray')) ))
end

function onEvent(n, v1, v2)
	v1 = stringTrim(v1:lower())
	if n == 'Change Character' then
		if getVar('paIconShi') then setProperty(iconSpr..'.fruitSprite.visible', true) end -- Revert the used icon back to its og state

		local charTag = 'boyfriend'
		if v1 == 'gf' or v1 == 'girlfriend' then
			charTag = 'gf'
		elseif v1 == 'dad' or v1 == 'opponent' then
			charTag = 'dad'
		else
			charTag = tagFromNumV1(v1)
		end
		setVar('paIconShi', stringEndsWith(v2, 'fight'))

		isPlayer = getProperty(charTag..'.isPlayer')
		setProperty('iconP3.isPlayer', isPlayer)

		iconSpr = 'iconP'..(isPlayer and '1' or '2')
		if getVar('paIconShi') then
			setProperty(iconSpr..'.fruitSprite.visible', false)
			setProperty('iconP3.visible', true)
		end

		setVar('extra', {
			['healthIcon'] = (isPlayer and _lastIconPlayer or _lastIcon),
			['healthColorArray'] = (isPlayer and _hpColorPlayer or _hpColor),
			['healthFruit'] = (isPlayer and _lastFruitPlayer or _lastFruit),
			['fruitColorArray'] = (isPlayer and _fruitColorPlayer or _fruitColor),
			['fruitAccentColor'] = (isPlayer and _fruitAccentPlayer or _fruitAccent)
		})

		if not customData then	
			local varSuffix = charTag == 'boyfriend' and 'Player' or ''
			_G['_lastIcon'..varSuffix] = getProperty(charTag..'.healthIcon')
			_G['_lastFruit'..varSuffix] = getProperty(charTag..'.healthFruit')
			_G['_hpColor'..varSuffix] = getProperty(charTag..'.healthColorArray')

			_G['_fruitColor'..varSuffix] = getProperty(charTag..'.fruitColorArray')
			_G['_fruitAccent'..varSuffix] = getProperty(charTag..'.fruitAccentColor')
		end
		tcholaMoment = true
	end
end