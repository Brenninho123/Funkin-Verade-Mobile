package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var bruno:FlxSprite;

	public function new()
	{
		title = Language.getPhrase('graphics_menu', 'Configurações de Gráficos');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		bruno = new FlxSprite(900, 0, Paths.image('titlescreen/bruno'));
		bruno.scale.set(0.2, 0.2); bruno.updateHitbox();
		bruno.screenCenter(Y).y -= 50;
		bruno.active = false;
		bruno.antialiasing = ClientPrefs.data.antialiasing;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Baixa Qualidade', //Name
			'Se marcado desativa alguns elementos do fundo,\ndiminuindo tempo de carregamento e melhorando um pouco a performance.', //Description
			'lowQuality', //Save data variable name
			BOOL); //Variable type
		addOption(option);

		var option:Option = new Option('Antialiasing',
			'Se desmarcado, desativa o "aliasing" de alguns sprites. Aliasing é o alisamento de sprites,\ncoisa essa que pode ser meio pesadinho pra sprites grandes.',
			'antialiasing',
			BOOL);
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length-1;

		var option:Option = new Option('Shaders', //Name
			"Se desmarcado, desativa shaders.\nEles servem pra alguns efeitos visuais maneiros porem podem ser intensos pra CPU.", //Description
			'shaders',
			BOOL);
		addOption(option);

		var option:Option = new Option('Caching na GPU', //Name
			"Deixa o mod usar a GPU invés da memória RAM pra 'cachear' texturas quando ativado.\nNão habilite isso se você tá jogando numa torradeira.", //Description
			'cacheOnGPU',
			BOOL);
		addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Nem preciso explicar né?",
			'framerate',
			INT);
		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 60;
		option.maxValue = 240;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%vFPS';
		option.onChange = onChangeFramerate;
		addOption(option);
		#end

		super();
		insert(1, bruno);
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		if (ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		bruno.visible = antialiasingOption == curSelected;
	}
}