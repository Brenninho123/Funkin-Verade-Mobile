package states;

import flixel.effects.FlxFlicker;
import flixel.util.typeLimit.NextState.InitialState;

class OutdatedState extends flixel.FlxState
{
	public static var updateVersion:String = "Unknown";
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
			'update_warn', 
			"Irmão, cê tem uma versão meio antiga do mod!\n" +
			"Se eu fosse você, recomendava atualizar pra não perder nadinha em..\n" +
			"(Versão Atual: {1} | Lançamento: {2})\n" +
			"Gostaria de atualizar o mod?", 
			[lime.app.Application.current.meta["version"], updateVersion]
		));
		warnText.setFormat(Paths.font("fraiche.ttf"), 52, FlxColor.WHITE, CENTER);
		warnText.screenCenter().y -= 32;
		warnText.active = false;
		warnText.antialiasing = ClientPrefs.data.antialiasing;
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
			button.antialiasing = ClientPrefs.data.antialiasing;
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
		if (curSelected == 1)
		{
			CoolUtil.browserLoad("https://github.com/BernardoGP4504/Funkin-Verade/releases");
			Sys.exit(0);
			return;
		}

		FlxFlicker.flicker(texts.members[curSelected], 1, 0.1, true, false, (_) -> FlxTimer.wait(0.5, () -> __getOut(0.2)));
	}

	inline function __getOut(hidingSpeed:Float)
	{
		FlxTween.num(1, 0, hidingSpeed, {onComplete: (_) -> FlxG.switchState(initialState.toNextState())}, (a) -> for (t in texts.members)
			t.alpha = a);
	}
}