package options;

import objects.StrumNote;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	var DOWNSCROLL_Y:Float;
	var notes:FlxTypedGroup<StrumNote>;
	var showNotes:Bool = true;

	public function new()
	{
		title = Language.getPhrase('gameplay_menu', 'Configurações de Gameplay');
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence
		DOWNSCROLL_Y = (FlxG.height - 150);

		notes = new FlxTypedGroup<StrumNote>(4);
		for (i in 0...notes.maxSize)
		{
			var note:StrumNote = new StrumNote(
				ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, 
				ClientPrefs.data.downScroll ? DOWNSCROLL_Y : PlayState.STRUM_Y, 
			i, 1);
			note.playerPosition();
			notes.add(note);
		}

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			"Se marcado, faz as notas irem pra baixo invés de irem pra cima, simples assim.", //Description
			'downScroll', //Save data variable name
			BOOL); //Variable type
		option.onChange = onScrollChange;
		addOption(option);

		var option:Option = new Option('Middlescroll',
			"Se marcado, suas notas ficam centralizadas na tela.",
			'middleScroll',
			BOOL);
		option.onChange = onScrollChange;
		addOption(option);

		var option:Option = new Option('Mostrar Notas do Oponente',
			"Controla se as notas do oponente devem ser visíveis.",
			'opponentStrums',
			BOOL);
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"Permite você apertar as setas mesmo não tendo nenhuma nota pra apertar, sem te dar misses por isso.",
			'ghostTapping',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Pause Automático',
			"Quando ativado, o jogo pausará se não estiver em foco.",
			'autoPause',
			BOOL);
		option.onChange = onChangeAutoPause;
		addOption(option);

		var option:Option = new Option('Desativar Reset',
			"Se marcado, apertar RESET não vai te matar.",
			'noReset',
			BOOL);
		addOption(option);

		var option:Option = new Option('Notas Longas Fundidas',
			"Se marcado, notas longas contam como um único hit/miss.\nDesmarque isso se preferir o input do FNF original.",
			'guitarHeroSustains',
			BOOL);
		addOption(option);

		var option:Option = new Option('Volume de Hitsound',
			"O quão as notinhas fazem \"Tic!\" quando acertadas.",
			'hitsoundVolume',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;
		addOption(option);

		var option:Option = new Option('Offset de Avaliação',
			'Muda o quão cedo ou tarde você deve apertar para melhores avaliações.\nValores maiores = depois',
			'ratingOffset',
			INT);
		option.displayFormat = '%vMS';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var scrollSpeed:Float = 15;
		for (i=>r in ['Sick', 'Good', 'Bad'])
		{
			var option:Option = new Option('Janela de Hit $r',
				'Muda o timing disponível pra pegar uma avaliação "$r", em milisegundos.',
				'${r.toLowerCase()}Window',
				FLOAT);
			option.displayFormat = '%vMS';
			option.scrollSpeed = scrollSpeed;
			option.minValue = 15;
			option.maxValue = 45 + (45 * i);
			option.changeValue = 0.1;
			
			addOption(option);
			scrollSpeed *= 2;
		}

		super();
		insert(members.indexOf(descBox), notes);
	}

	inline function onChangeHitsoundVolume()
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

	inline function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		if (showNotes == (showNotes = curOption.variable.endsWith('Scroll'))) return;

		final targetAlpha:Float = !showNotes ? 0.0001 : 1;
		for (n in notes.members)
		{
			FlxTween.cancelTweensOf(n, ['alpha']);
			FlxTween.tween(n, {alpha: targetAlpha}, 0.5, {ease: FlxEase.cubeOut});
		}
	}

	function onScrollChange()
	{
		var targetPos:Float = 0;
		final changeY:Bool = curOption.variable.startsWith('down');

		if (changeY)
			targetPos = curOption.getValue() ? DOWNSCROLL_Y : PlayState.STRUM_Y;
		else
			targetPos = curOption.getValue() ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;

		for (i=>n in notes.members)
		{
			final xAdd:Float = (objects.Note.swagWidth * i) + 50 + (FlxG.width / 2);

			FlxTween.completeTweensOf(n, ['x', 'y']);
			FlxTween.tween(n, {x: !changeY ? (targetPos + xAdd) : n.x, y: changeY ? targetPos : n.y}, 1, {ease: FlxEase.cubeOut});
		}
	}
}
