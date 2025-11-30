local this = ""
local charCheck = ""
local weExistin = false

local cinemaIntrodid = false
local prevX = 0
local prevY = 0

function onCreatePost()
	if _G[charCheck..'Name'] ~= this or weExistin then return end
	weExistin = true
	prevX = getProperty(charCheck..'.x')
	prevY = getProperty(charCheck..'.y')

	makeLuaSprite('blufiBG', 'characters/briga_de_macas/blufi-B', -18, screenHeight * 2)
	setScrollFactor('blufiBG', 0, 0)
	addToGroup('gfGroup', 'blufiBG')

	setProperty(charCheck..'.x', (getProperty(charCheck..'.x') + getProperty(charCheck..'.width')) / 2)
	setProperty(charCheck..'.y', screenHeight * 2)
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

	precacheImage('characters/briga_de_macas/blufi-B')
end

function goodNoteHit(_, _, _, s)
	if (cinemaIntrodid or not weExistin) or s then return end

	doTweenY('cinemaBlufi', charCheck, prevY, 0.45, 'cubeOut')
	doTweenY('cinemaBG', 'blufiBG', prevY, 0.45, 'cubeOut')
	cinemaIntrodid = true
end

function onTweenCompleted(tag)
	if tag ~= 'cinemaBGout' then return end
	removeLuaSprite('blufiBG', true, 'gfGroup')
	close()
end

function onDestroy() doTweenY('cinemaBGout', 'blufiBG', screenHeight * 2, 0.45, 'cubeOut') end

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
	elseif weExistin and changedCharCheck == charCheck then
		onDestroy()
	end
end