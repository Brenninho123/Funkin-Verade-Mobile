package states;

import flixel.effects.FlxFlicker;
import flixel.util.typeLimit.NextState.InitialState;

class FlashingState extends flixel.FlxState
{
	static inline final UNSELECT_ALPHA:Float = 0.6;

	var blockInput:Bool = false;
	var curSelected:Int = 1;

	final initialState:InitialState;
	var texts:FlxTypedGroup<FlxText>;

	@:allow(Main)
	function new(initialState:InitialState)
	{
		this.initialState = initialState;
		super();	
	}

	override function create()
	{
		FlxG.mouse.visible = false;
		super.create();

		texts = new FlxTypedGroup<FlxText>();
		add(texts);

		var warnText:FlxText = new FlxText(0, 0, FlxG.width, Language.getPhrase(
			'flasing_warn',
			"Opa, cuidado aí!\n" +
			"Esse Mod contém luzes piscantes!\n" +
			"Deseja desativá-las?"
		));
		warnText.setFormat(Paths.font("fraiche.ttf"), 56, FlxColor.WHITE, CENTER);
		warnText.screenCenter().y -= 32;
		warnText.active = false;
		warnText.antialiasing = true;
		texts.add(warnText);

		var keys:Array<String> = [Language.getPhrase('warn_y', "Sim"), Language.getPhrase('warn_n', "Não")];
		for (i in 0...keys.length)
		{
			var button = new FlxText(0, (warnText.y + warnText.height) + 24, 0, keys[i]);
			button.setFormat(Paths.font("fraiche.ttf"), 52, 0xFFFFC857, CENTER);
			button.screenCenter(X).x -= button.width;
			button.x += (button.width * 2) * i;
			button.alpha = UNSELECT_ALPHA;
			button.active = false;
			button.antialiasing = true;
			texts.add(button);
		}
		keys.resize(0);

		changeSelection(0);
	}

	override function update(elapsed:Float)
	{
		if (blockInput)
		{
			super.update(elapsed);
			return;
		}
		
		final left_p:Bool = Controls.instance.UI_LEFT_P;
		if (left_p || Controls.instance.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound("scrollMenu"));
			changeSelection(left_p ? -1 : 1);
		}

		if (Controls.instance.ACCEPT)
		{
			blockInput = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			choseOption();
		}

		super.update(elapsed);
	}

	inline function changeSelection(change:Int)
	{
		texts.members[curSelected].alpha = UNSELECT_ALPHA;

		curSelected = FlxMath.wrap(curSelected + change, 1, texts.length - 1);
		texts.members[curSelected].alpha = 1;
	}

	function choseOption()
	{
		ClientPrefs.data.flashing = curSelected != 1;
		ClientPrefs.saveSettings();

		FlxFlicker.flicker(texts.members[curSelected], 1, 0.1, true, false, (_) -> FlxTimer.wait(0.5, () -> __getOut(0.2)));
	}

	inline function __getOut(hidingSpeed:Float)
	{
		FlxTween.num(1, 0, hidingSpeed, {onComplete: (_) -> FlxG.switchState(initialState.toNextState())}, (a) -> for (t in texts.members)
			t.alpha = a);
	}
}