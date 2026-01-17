package options;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import objects.Alphabet;

class VisualsSettingsSubState extends BaseOptionsMenu
{
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var noteY:Float = 90;

	public function new()
	{
		title = Language.getPhrase('visuals_menu', 'Configurações Visuais e Outros');
		rpcTitle = 'Visual and Miscellaneous Settings Menu'; //for Discord Rich Presence

		// for note skins and splash skins
		notes = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			notes.add(note);
			
			var splash:NoteSplash = new NoteSplash(0, 0, NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix());
			splash.inEditor = true;
			splash.babyArrow = note;
			splash.ID = i;
			splash.kill();
			splashes.add(splash);
		}

		// options
		var option:Option = new Option('Opacidade de Note Splash',
			"O quão transparente devem ser os splashes das notas.",
			'splashAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = playNoteSplashes;
		addOption(option);
		noteOptionID = optionsArray.length - 1;

		var option:Option = new Option('Esconder HUD',
			"Se marcado, esconde a maioria da HUD.\nDeixando Dispositivos Bomba respirarem melhor na gameplay.",
			'hideHud',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Barra de Tempo:',
			"Controla o comportamento da barra de tempo.",
			'timeBarType',
			STRING,
			['Restante', 'Decorrente', 'Nome da Música', 'Desativada']);
		addOption(option);

		var option:Option = new Option('Luzes Piscantes',
			"Desative isso se for sensível a luzes piscantes!",
			'flashing',
			BOOL);
		addOption(option);

		var option:Option = new Option('Zooms de Camera',
			"Se desmarcado, a camera não vai dar zoom em batidas.",
			'camZooms',
			BOOL);
		addOption(option);

		var option:Option = new Option('Bop de Pontuação',
			"Controla se o texto de pontuação deve fazer um \"bop\" a cada acerto de nota.",
			'scoreZoom',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Contador de FPS',
			"Se desmarcado, esconde o contador de FPS e Memória.",
			'showFPS',
			BOOL);
		option.onChange = onChangeFPSCounter;
		addOption(option);
		
		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Buscar Atualizações',
			"Ligue isso para automaticamente procurar atualizações ao iniciar do jogo.",
			'checkForUpdates',
			BOOL);
		addOption(option);
		#end

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Desmarcar isso esconde o coiso de \"Jogando\" do Discord.",
			'discordRPC',
			BOOL);
		addOption(option);
		#end

		super();
		add(notes);
		add(splashes);
	}

	var notesShown:Bool = false;
	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		
		switch(curOption.variable)
		{
			case 'splashAlpha':
				if(!notesShown)
				{
					for (note in notes.members)
					{
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = true;
				if(Math.abs(notes.members[0].y - noteY) < 25) playNoteSplashes();

			default:
				if(notesShown) 
				{
					for (note in notes.members)
					{
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = false;
		}
	}

	function playNoteSplashes()
	{
		var rand:Int = 0;
		if (splashes.members[0] != null && splashes.members[0].maxAnims > 1)
			rand = FlxG.random.int(0, splashes.members[0].maxAnims - 1); // For playing the same random animation on all 4 splashes

		for (splash in splashes)
		{
			splash.revive();

			splash.spawnSplashNote(0, 0, splash.ID, null, false);
			if (splash.maxAnims > 1)
				splash.noteData = splash.noteData % Note.colArray.length + (rand * Note.colArray.length);

			var anim:String = splash.playDefaultAnim();
			var conf = splash.config.animations.get(anim);
			var offsets:Array<Float> = [0, 0];

			var minFps:Int = 22;
			var maxFps:Int = 26;
			if (conf != null)
			{
				offsets = conf.offsets;

				minFps = conf.fps[0];
				if (minFps < 0) minFps = 0;

				maxFps = conf.fps[1];
				if (maxFps < 0) maxFps = 0;
			}

			splash.offset.set(10, 10);
			if (offsets != null)
			{
				splash.offset.x += offsets[0];
				splash.offset.y += offsets[1];
			}

			if (splash.animation.curAnim != null)
				splash.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}

	override function destroy()
	{
		Note.globalRgbShaders = [];
		super.destroy();
	}

	function onChangeFPSCounter()
	{
		if (Main.fpsVar == null) return;
		Main.fpsVar.visible = ClientPrefs.data.showFPS;
	}
}
