local intro = false
local scrollDirection = (downscroll and -1 or 1)

function onCreate()
	for _, c in pairs({"t", "m"}) do precacheImage('transitions/tojoTchola-'..c) end
	
makeLuaSprite('barTop', '', 0, -200)
makeGraphic('barTop', screenWidth, 400, '000000')
setObjectCamera('barTop', 'hud')
addLuaSprite('barTop', true)

makeLuaSprite('barBottom', '', 0, screenHeight)
makeGraphic('barBottom', screenWidth, 400, '000000')
setObjectCamera('barBottom', 'hud')
addLuaSprite('barBottom', true)

setObjectOrder('barTop', getProperty('uiGroup'))
setObjectOrder('barBottom', getProperty('uiGroup'))
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
	
	if curStep == 3 then
setProperty('cameraSpeed', 0.25)
triggerEvent('Camera Follow Pos','934','899')
end

if curStep== 60 then
moveTo('dad')
setProperty('cameraSpeed', 999)
triggerEvent('Set Camera Zoom','0.85','0.01')
end

if curStep== 62 then
moveTo('nil')
cameraSetTarget('boyfriend')
setProperty('cameraSpeed', 0.25)
triggerEvent('Set Camera Zoom','0.6','8')
end

if curStep == 64 then
local scrollSpeed = getProperty('songSpeed')
	for nota = 0, 7 do
		local strumline = nota > 3 and 'Player' or 'Opponent'
		noteTweenY('seta'..nota..'Y', nota, _G['default'..strumline..'StrumY'..(nota % 4)], scrollSpeed, 'quadOut')
	end

doTweenY('healthBarY', 'healthBar', getProperty('healthBar.y')- (200 * scrollDirection), scrollSpeed,'quadOut')
doTweenY('scoreTxtY', 'scoreTxt', getProperty('scoreTxt.y')- (200 * scrollDirection), scrollSpeed,'quadOut')

doTweenY('timeTxtY', 'timeTxt', getProperty('timeTxt.y')+ (150 * scrollDirection), scrollSpeed,'quadOut')
doTweenY('timeBarY', 'timeBar', getProperty('timeBar.y')+ (150 * scrollDirection), scrollSpeed,'quadOut')

doTweenY('iconP1Y', 'iconP1', getProperty('iconP1.y')- (200 * scrollDirection), scrollSpeed,'quadOut')
doTweenY('iconP2Y', 'iconP2', getProperty('iconP2.y')- (200 * scrollDirection), scrollSpeed,'quadOut')
end

if curStep== 120 then
intro = true
setProperty('cameraSpeed', 1)
end

if curStep== 192 then
setProperty('cameraSpeed', 0.45)
triggerEvent('Set Camera Zoom','0.65','2')
end

if curStep== 208 then
setProperty('cameraSpeed', 1)
end

if curStep== 210 then
triggerEvent('Set Camera Zoom','0.6','2')
end

if curStep== 233 then
moveTo('dad')
setProperty('cameraSpeed', 999)
triggerEvent('Set Camera Zoom','0.75','1')
end

if curStep== 236 then
moveTo('nil')
setProperty('cameraSpeed', 1)
triggerEvent('Set Camera Zoom','0.6','2')
end

if curStep== 320 or curStep== 768 then
setProperty('flash.alpha', 0.8 / (not flashingLights and 1 or 2))
doTweenAlpha('flTw','flash',0.01,2,'linear')
end

if curStep== 682 then
moveTo('dad')
setProperty('cameraSpeed', 999)
triggerEvent('Set Camera Zoom','0.75','1')
end

if curStep== 688 then
moveTo('nil')
setProperty('cameraSpeed', 1)
triggerEvent('Set Camera Zoom','0.6','2')
end

if curStep== 808 then
setProperty('cameraSpeed', 0.65)
triggerEvent('Set Camera Zoom','0.55','2')
end

if curStep== 816 then
setProperty('cameraSpeed', 1)
triggerEvent('Set Camera Zoom','0.6','2')
end

if curStep== 825 then
moveTo('dad')
setProperty('cameraSpeed', 999)
end

if curStep== 832 then
moveTo('nil')
setProperty('cameraSpeed', 1)
end
end

function onCreatePost()
makeLuaSprite('flash', '', -2, -2);
makeGraphic('flash',screenWidth+4,screenHeight+4,'ffffff')
addLuaSprite('flash', false);
setObjectCamera('flash', 'other')
setBlendMode('flash', 'add')
setProperty('flash.alpha', 0.0001)


setProperty('healthBar.y', getProperty('healthBar.y') + (200 * scrollDirection))
setProperty('scoreTxt.y', getProperty('scoreTxt.y') + (200 * scrollDirection))
setProperty('timeBar.y', getProperty('timeBar.y') - (150 * scrollDirection))
setProperty('timeTxt.y', getProperty('timeTxt.y') - (150 * scrollDirection))
setProperty('iconP1.y', getProperty('iconP1.y') + (200 * scrollDirection))
setProperty('iconP2.y', getProperty('iconP2.y') + (200 * scrollDirection))

triggerEvent('Cinematic','on','0.01')
triggerEvent('Set Camera Zoom','1.25','1')
	setProperty('skipArrowStartTween', true)
end

function onCountdownStarted()
	for nota = 0, 7 do
		local strumline = nota > 3 and 'player' or 'opponent'
		setPropertyFromGroup(strumline..'Strums', nota % 4, 'y', getPropertyFromGroup(strumline..'Strums', nota % 4, 'y') - (200 * scrollDirection))
	end
end

function onSongStart()
triggerEvent('Cinematic','off','10')
triggerEvent('Set Camera Zoom','0.55','10')
triggerEvent('Camera Follow Pos','1700','500')
end

function onTweenCompleted(tag)
	if tag == 'mojoChill' then
		removeLuaSprite('tojoChill')
		removeLuaSprite('mojoChill')
	end
end

function onEvent(name,v1,v2, strumTime)
if intro then
if name == 'Camera Follow Pos' then
if v1 == '935' and v2 == '900' then
setProperty('cameraSpeed', 0.85)
triggerEvent('Set Camera Zoom','0.55','1')
elseif v1 == '' and v2 == '' then
setProperty('cameraSpeed', 1)
triggerEvent('Set Camera Zoom','0.6','1')
end
end

	if name ~= 'Lyrics' then return end

	if v1 == "Tchoooola," then
		makeLuaSprite('tojoSmug', 'transitions/tojoTchola-t', screenWidth)
		screenCenter('tojoSmug', "y")
		setObjectCamera('tojoSmug', 'hud')

		doTweenX('phraseSteal', 'tojoSmug', screenWidth - (getProperty('tojoSmug.width') / 1.1), 0.75, 'circOut')
		addLuaSprite('tojoSmug')
	elseif v1 == "Tchoooola,O" then
		makeLuaSprite('mojoAngy', 'transitions/tojoTchola-m', -screenWidth)
		screenCenter('mojoAngy', "y") setProperty('mojoAngy.y', getProperty('mojoAngy.y') - 24)
		setObjectCamera('mojoAngy', 'hud')

		doTweenX('WHATHEFU', 'mojoAngy', 0, 0.75, 'circOut')
		setObjectOrder('mojoAngy', getObjectOrder('tojoSmug') - 1)
	elseif v1 == "" then
		doTweenX('tojoChill', 'tojoSmug', screenWidth, 0.5, 'quartOut')
		doTweenX('mojoChill', 'mojoAngy', -screenWidth, 0.5, 'quartOut')
	end
end

if name == 'Cinematic' then
if v1 == 'on' then
doTweenY('barTopIn', 'barTop', 0, tonumber(v2), 'sineOut')
doTweenY('barBotIn', 'barBottom', 400, tonumber(v2), 'sineOut')

elseif v1 == 'off' then
doTweenY('barTopOut', 'barTop', -1200, tonumber(v2), 'sineOut')
doTweenY('barBotOut', 'barBottom', 1200, tonumber(v2), 'sineOut')
end
end
end

function moveTo(state)
if state == 'dad' then
triggerEvent('Camera Follow Pos',getMidpointX('dad'),getMidpointY('dad'))
cameraSetTarget('dad')
end

if state == 'bf' then
triggerEvent('Camera Follow Pos',getMidpointX('boyfriend'),getMidpointY('boyfriend'))
cameraSetTarget('boyfriend')
end

if state == 'nil' then
triggerEvent('Camera Follow Pos','','')
end
end