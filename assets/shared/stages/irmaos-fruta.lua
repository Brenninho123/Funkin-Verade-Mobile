function onCreate()
	makeLuaSprite('Fundo1', "Fundo1", -520, 0)
	scaleObject('Fundo1', 1.2, 1.2)
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
	close()
end