package states.editors;

import backend.WeekData;

class MasterEditorMenu extends flixel.FlxSubState
{
	final options:Array<String> = 
	[
		'Charter',
		'Character Editor',
		'Stage Editor',
		'Week Editor',
		'Week Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Note Splash Editor'
	];
	static var curSelected = 0;
	
	final mouseLastVis:Bool;
	var blockInput:Bool = false;

	#if MODS_ALLOWED
	var directories:Array<String> = [null];
	static var curDirectory = 0;

	var directoryTxt:FlxText;
	#end
	var grpTexts:FlxTypedGroup<Alphabet>;

	public function new()
	{
		mouseLastVis = FlxG.mouse.visible;
		super(0x90000000);
	}

	override function create()
	{
		FlxG.mouse.visible = false;
		super.create();

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (p=>o in options)
		{
			var leText:Alphabet = new Alphabet(0, 320, o);
			leText.isMenuItem = true;
			leText.targetY = p;
			leText.changeX = false;
			leText.screenCenter(X);
			leText.alpha = 0.6;
			grpTexts.add(leText);
		}
		changeSelection(0);
		
		#if MODS_ALLOWED
		for (folder in Mods.getModDirectories()) directories.push(folder);
		final found:Int = directories.indexOf(Mods.currentModDirectory);
		if (found != -1) curDirectory = found;

		directoryTxt = new FlxText(0, FlxG.height, FlxG.width);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		changeDirectory(0);
		directoryTxt.y -= directoryTxt.height - (directoryTxt.size + 10);
		add(directoryTxt);

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, (directoryTxt.size + 10), 0xFFFFFFFF);
		textBG.y -= textBG.height;
		textBG.alpha = 0.6;
		add(textBG);
		#end
	}

	override function update(elapsed:Float)
	{
		if (blockInput)
		{
			super.update(elapsed);
			return;
		}

		if (Controls.instance.UI_UP_P) changeSelection(-1);
		if (Controls.instance.UI_DOWN_P) changeSelection(1);
		#if MODS_ALLOWED
		if (Controls.instance.UI_LEFT_P) changeDirectory(-1);
		if (Controls.instance.UI_RIGHT_P) changeDirectory(1);
		#end

		if (Controls.instance.BACK)
		{
			FlxG.mouse.visible = mouseLastVis;
			close();
		}
		if (Controls.instance.ACCEPT) selectItem(options[curSelected].toLowerCase());
		
		super.update(elapsed);
	}

	function changeSelection(change:Int)
	{
		grpTexts.members[curSelected].alpha = 0.6;

		if (change != 0) curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (i=>t in grpTexts.members) t.targetY = i - curSelected;
		grpTexts.members[curSelected].alpha = 1;
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int)
	{
		if (change != 0)
		{
			curDirectory = FlxMath.wrap(curDirectory + change, 0, directories.length - 1);
			WeekData.setDirectoryFromWeek();
			Mods.currentModDirectory = directories[curDirectory];
		}

		if (directories[curDirectory] == null) directoryTxt.text = '< No Mod Directory >';
		else directoryTxt.text = '< Mod Directory to Edit: ${directories[curDirectory]} >';
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end

	function selectItem(choice:String)
	{
		MusicBeatState.customTransClass = "";
		var state:flixel.util.typeLimit.NextState = switch (choice)
		{
			case 'charter': () -> new ChartingState();
			case 'character editor': () -> new CharacterEditorState(null, false);
			case 'stage editor': () -> new StageEditorState();
			case 'week editor': () -> new WeekEditorState();
			case 'week character editor': () -> new MenuCharacterEditorState();
			case 'dialogue editor': () -> new DialogueEditorState();
			case 'dialogue portrait editor': () -> new DialogueCharacterEditorState();
			case 'note splash editor': () -> new NoteSplashEditorState();
			default: null;
		};

		if (state == null)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.log.warn('"$choice" doesn\'t do anything');

			return;
		}
		blockInput = true;

		FreeplayState.destroyFreeplayVocals();
		FlxG.mouse.visible = true;
		FlxG.switchState(state);
	}
}