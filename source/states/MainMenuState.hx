package states;

import flixel.input.keyboard.FlxKey;
import backend.WeekData;
import backend.Song;
import flixel.util.typeLimit.NextState;

private enum abstract AlignType(String) from String
{
	final CENTER:String = "centered";
	final BOTTOM_LEFT:String = "bottomL";
	final BOTTOM_RIGHT:String = "bottomR";
	final TOP_LEFT:String = "topL";
	final TOP_RIGHT:String = "topR";
}

private typedef RenderData = 
{
	imageName:String,
	offset:Array<Float>,
	scale:Float,
	?originAlign:AlignType
}

private typedef MenuOpt = 
{
	offset:Array<Float>,
	scale:Float,
	render:RenderData
}

class MainMenuState extends MusicBeatState
{
	var optionShit:Array<String> = [];
	static final datasPath:String = Paths.getSharedPath('data/menus/main/');
	static var curSelected:Int = 0;

	var selectedSomethin:Bool = false;
	var selectionShit:Map<Int, Array<String>> = [];

	var menuItems:FlxTypedGroup<FlxSprite>;

	var menuColors:Array<FlxColor> = [];
	var bgGrad:FlxSprite;

	var renderSprs:Array<FlxSprite> = [];
	// Neat bopping effect
	var renderScales:Array<Float> = [];
	final bopInterval:Int = 2;
	final lerpSpeed:Float = 6;

	var easterEggs:Map<String, Void->Void> = [];
	var eggsLastClues:Array<Int> = [];
	var eggsLastGuesses:Array<String> = [];
	var eggHunts:Array<Void->Void> = [];
	var lastFoundEgg:String = "";

	@:noCompletion inline function __selectionDataFromNode(element:Xml):Array<String>
	{
		var selectionData:Array<String> = [];
		for (d in element.elements())
		{
			selectionData.push(
				#if DEMO
				d.get("demo").length > 0 ? d.get("demo") : d.get("default")
				#else
				d.get("default")
				#end);
		}

		if (selectionData[selectionData.length - 1].length == 0) selectionData.resize(1);
		return selectionData;
	}

	public function new()
	{
		final optionData:Xml = Xml.parse(Paths.getTextFromFile('${datasPath}options.xml')).firstElement();

		var i:Int = 0;
		for (e in optionData.elements())
		{
			optionShit.push(e.get("name"));
			if (e.firstElement() == null) continue;

			selectionShit[i++] = __selectionDataFromNode(e);
		}

		super();
	}

	override function create()
	{
		FlxG.mouse.visible = false;
		CoolUtil.playMenuSong();

		if (optionShit.length == 0)
		{
			selectedSomethin = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxTransitionableState.skipNextTransIn = true;

			FlxG.switchState(function() 
			{
				return new ErrorState(
					'No menu items were found!! Try making sure options are added correctly in "${datasPath}options.xml".\nPress ACCEPT to Reload | Press BACK to Leave this Menu',
					() -> FlxG.switchState(() -> new MainMenuState()),
					() -> FlxG.switchState(() -> new TitleState())
				);
			});
			return;
		}

		// Easter eggs são assinalados aqui pq não se pode acessar funções locais no declarar de variáveis
		EasterEggs.state = this;
		FlxG.signals.postUpdate.add(EasterEggs.onUpdate);
		easterEggs = 
		[
			"abel" => EasterEggs.spawnAbels/* ,
			"algorithomus" => FlxG.resetGame */
		];

		var eggId:Int = 0;
		for (clues=>egg in easterEggs)
		{
			eggsLastClues.push(-1);
			eggsLastGuesses.push("");
			final huntTask:Void->Void = huntForEgg.bind(egg, eggId, clues);

			eggHunts.push(huntTask);
			FlxG.signals.preUpdate.add(huntTask);
			++eggId;
		}

		super.create();
		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Menus"); #end

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image('menuBG'));
		bg.screenCenter();
		bg.flipX = true;
		bg.active = false;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		if (!ClientPrefs.data.lowQuality)
		{	
			bgGrad = new FlxSprite(0, 0, flixel.util.FlxGradient.createGradientBitmapData(1, FlxG.height, [0xFFADADAD, 0xFF3F3F3F]));
			bgGrad.scale.x = FlxG.width; bgGrad.updateHitbox();
			bgGrad.screenCenter();
			bgGrad.active = false;
			bgGrad.antialiasing = false;
			bgGrad.blend = MULTIPLY;
			add(bgGrad);

			var bgGrid:flixel.addons.display.FlxBackdrop = new flixel.addons.display.FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(20, 20, 40, 40, true, FlxColor.WHITE, FlxColor.TRANSPARENT));
			bgGrid.scale.set(1.85, 1.85); bgGrid.updateHitbox();
			bgGrid.velocity.set(-24, 24);
			bgGrid.alpha = 0.13;
			add(bgGrid);
		}

		menuItems = new FlxTypedGroup<FlxSprite>();
		for (o in optionShit)
		{
			final optData:MenuOpt = haxe.Json.parse(Paths.getTextFromFile('${datasPath}opt_$o.json'));

			var item:FlxSprite = createMenuItem(o, 30, -200 / ((optionShit.length / 2) - 1), optData);
			if (bgGrad != null) menuColors.push(CoolUtil.dominantColor(item));

			createRender(optData.render);
		}

		var overlay:FlxSprite = new FlxSprite(0, 0, Paths.image('mainmenu/overlay'));
		overlay.setGraphicSize(FlxG.width, FlxG.height); overlay.updateHitbox();
		overlay.screenCenter();
		overlay.active = false;
		overlay.antialiasing = ClientPrefs.data.antialiasing;
		add(overlay);
		add(menuItems);

		var psychVer:FlxText = new FlxText(0, 0, 0, 'Funkin\' Verade V${lime.app.Application.current.meta["version"]}\nPsych V1.0.4');
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		psychVer.setPosition(
			(FlxG.width - psychVer.width) - psychVer.size, 
			(FlxG.height - psychVer.height) - psychVer.size
		);
		psychVer.active = false;
		add(psychVer);

		changeItem(0);
		if (!ClientPrefs.data.lowQuality) beatHit(); // Em caso de vc entrar no menu sem a música tar na batida, pelo menos um bop vai ocorrer. De nada :3 -@BernardoGP4504
	}

	function createMenuItem(name:String, x:Float, y:Float, data:MenuOpt):FlxSprite
	{
		final defScale:Float = 1.35 / optionShit.length;

		var spr:FlxSprite = new FlxSprite(x, y);
		spr.frames = Paths.getSparrowAtlas('mainmenu/options/$name', false);
		spr.animation.addByPrefix('idle', 'NaoSelecionado', 0, false);
		spr.animation.addByPrefix('selected', 'Selecionado', 24);
		spr.animation.play('idle');

		spr.scale.set(defScale * data.scale, defScale * data.scale); spr.updateHitbox();
		spr.y += ((spr.height * spr.scale.y) * optionShit.indexOf(name)) + 90;
		spr.offset.add(-data.offset[0], -data.offset[1]);
		
		spr.antialiasing = ClientPrefs.data.antialiasing;
		menuItems.add(spr);
		return spr;
	}

	function createRender(data:RenderData)
	{
		data.originAlign ??= AlignType.CENTER;

		var spr:FlxSprite = new FlxSprite(FlxG.width / 2.5, 0, Paths.image('mainmenu/renders/${data.imageName}'));
		spr.scale.set(data.scale, data.scale); spr.updateHitbox();
		spr.screenCenter(Y);
		spr.active = false;
		spr.visible = false;
		spr.antialiasing = true;

		final originOffsets:Array<Float> = switch (data.originAlign)
		{
			case CENTER: [0.5, 0.5];
			case BOTTOM_LEFT: [0.2, 0.8];
			case BOTTOM_RIGHT: [0.8, 0.8];
			case TOP_LEFT: [0.2, 0.2];
			case TOP_RIGHT: [0.8, 0.2];
		};
		spr.origin.set(spr.frameWidth * originOffsets[0], spr.frameHeight * originOffsets[1]);
		spr.offset.set(-data.offset[0], -data.offset[1]);

		renderSprs.push(spr);
		if (!ClientPrefs.data.lowQuality) renderScales.push(data.scale);
		add(spr);
	}

	override function update(elapsed:Float)
	{
		if (selectedSomethin)
		{
			super.update(elapsed);
			return;
		}
		if (FlxG.sound.music?.playing) Conductor.songPosition = FlxG.sound.music.time;

		final up_p:Bool = controls.UI_UP_P;
		if (up_p || controls.UI_DOWN_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeItem(1 * (up_p ? -1 : 1));
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound("cancelMenu"));
			FlxG.switchState(() -> new TitleState());
		}
		if (controls.ACCEPT) chooseItem();

		#if debug
		if (FlxG.keys.justPressed.F5) FlxG.resetState();
		#end

		#if EDITORS_ALLOWED
		if (controls.justPressed('debug_1'))
		{
			selectedSomethin = true;

			var editorsMenu:flixel.FlxSubState = new states.editors.MasterEditorMenu();
			editorsMenu.closeCallback = () -> selectedSomethin = false;
			openSubState(editorsMenu);
		}
		#end

		super.update(elapsed);
		FlxG.watch.addQuick("lastPressedEaster", eggsLastClues);
		FlxG.watch.addQuick("lastTypedEaster", eggsLastGuesses);
		if (renderScales.length == 0) return;

		renderSprs[curSelected].scale.set(
			FlxMath.lerp(renderScales[curSelected], renderSprs[curSelected].scale.x, Math.exp(-elapsed * lerpSpeed)),
			FlxMath.lerp(renderScales[curSelected], renderSprs[curSelected].scale.y, Math.exp(-elapsed * lerpSpeed))
		);
	}

	override function beatHit()
	{
		if (curBeat % bopInterval != 0 || renderScales.length == 0) return;
		renderSprs[curSelected].scale.add(0.024, 0.024);
	}

	function huntForEgg(egg:Void->Void, eggId:Int, clues:String)
	{
		if (FlxG.keys.firstJustPressed() == -1 || lastFoundEgg.length > 0) return;
		var eachClue:Array<String> = clues.split("");
		function resetProgress()
		{
			eggsLastClues[eggId] = -1;
			eggsLastGuesses[eggId] = "";
		}

		if (FlxG.keys.firstJustPressed() == FlxKey.fromString(eachClue[eggsLastClues[eggId] + 1])) eggsLastGuesses[eggId] += eachClue[++eggsLastClues[eggId]];
		else resetProgress();

		if (eggsLastGuesses[eggId] == clues.toLowerCase())
		{
			lastFoundEgg = clues.toLowerCase();
			// Cleanup
			resetProgress();
			eachClue.resize(0);

			FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
			egg();

			lastFoundEgg = "";
			for (c in eggsLastClues) c = -1;
			for (g in eggsLastGuesses) g = "";
		}
	}

	// "Easter Hunt" cleanup
	override function destroy()
	{
		for (hunt in eggHunts) FlxG.signals.preUpdate.remove(hunt);
		eggHunts.resize(0);
		easterEggs.clear();
		eggsLastClues.resize(0);
		eggsLastGuesses.resize(0);

		FlxG.signals.postUpdate.remove(EasterEggs.onUpdate);
		EasterEggs.onDestroy();
		super.destroy();
	}

	function changeItem(change:Int)
	{
		menuItems.members[curSelected].animation.play("idle");
		renderSprs[curSelected].visible = false;

		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		menuItems.members[curSelected].animation.play("selected");

		renderSprs[curSelected].visible = true;
		if (menuColors.length != 0) bgGrad.color = menuColors[curSelected];
	}

	function chooseItem()
	{
		function unchooseItem()
		{
			FlxG.sound.play(Paths.sound("cancelMenu"));
			FlxG.log.warn('"${optionShit[curSelected]}" doesn\'t do anything');
		}

		if (!selectionShit.exists(curSelected))
		{
			unchooseItem();
			return;
		}

		final classFromStr = Type.resolveClass(selectionShit[curSelected][0]);
		if (classFromStr == null)
		{
			unchooseItem();
			return;
		}

		final targetState = Type.createInstance(classFromStr, []);
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound("confirmMenu"));

		var stateSwitch:NextState->Void = null;
		if (selectionShit[curSelected].length < 2)
		{
			stateSwitch = (s) -> __getToNextState(s);
			__doExitAnim(() -> targetState, stateSwitch);
			return;
		}

		stateSwitch = (s) -> __getToNextState(s, Reflect.field(this, selectionShit[curSelected][1]));	
		__doExitAnim(() -> targetState, stateSwitch);
	}

	@:noCompletion function __doExitAnim(state:NextState, exit:NextState->Void)
	{
		flixel.effects.FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, true, true, (_) -> exit(state));
		for (p=>i in menuItems.members)
		{
			if (p == curSelected) continue;
			FlxTween.tween(i, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
		}
	}

	@:noCompletion function __getToNextState(state:NextState, ?preloadPrep:haxe.Constraints.Function)
	{
		if (preloadPrep == null)
		{
			FlxG.switchState(state);
			return;
		}

		Reflect.callMethod(this, preloadPrep, []);
		LoadingState.loadAndSwitchState(state.createInstance());
	}

	#if DEMO
	@:noCompletion function preparePlayState()
	{
		WeekData.reloadWeekFiles(true); // WeekData.weeksList doesn't get set until we do this
		PlayState.storyPlaylist = [for (s in WeekData.getCurrentWeek().songs) s[0]]; // Make sure to set PlayState.currentWeek beforehand or it'll grab the first week
		PlayState.isStoryMode = true;

		Song.loadFromJson(PlayState.storyPlaylist[0]);
		PlayState.campaignScore = 0;
		PlayState.campaignMisses = 0;
		LoadingState.prepareToSong();
	}
	#end
}

private class EasterEggs
{
	public static var state:flixel.FlxState;
	static var abels:Array<FlxSprite> = [];

	public static function spawnAbels()
	{
		#if ACHIEVEMENTS_ALLOWED Achievements.unlock("abel.webp"); #end
		var abel:FlxSprite = new FlxSprite(0, 0, Paths.image('credits/abel'));
		abel.scale.set(0.1, 0.1); abel.updateHitbox();

		final posX:Float = FlxG.random.float(40, (FlxG.width - abel.width) - 40);
		final posY:Float = FlxG.random.float(40, (FlxG.height - abel.height) - 40);
		abel.setPosition(posX, posY);

		abel.velocity.set(0, 280);
		abel.drag.set(0, 15);
		abels.push(abel);
		state.add(abel);
	}

	public static function onUpdate()
	{
		if (abels.length > 0)
		{
			for (abel in abels)
			{
				var bounds:flixel.math.FlxRect = FlxG.camera.getViewMarginRect();
				FlxG.watch.addQuick("cam bounds for abel", bounds);

				final abelHeight:Float = abel.y + abel.height;
				final abelWidth:Float = abel.y + abel.width;

				if (abelHeight > (bounds.bottom * 1.1))
				{
					FlxTween.tween(abel, {y: abel.y - 12}, 0.23, {ease: FlxEase.backOut, type: PINGPONG});
					abel.velocity.set(14, -0.24);
				}

				if (abelWidth >= bounds.right)
				{
					abel.velocity.x *= -1;
					FlxTween.tween(abel, {x: abel.x - 12, "scale.x": -abel.scale.x}, 0.23, {ease: FlxEase.backOut});
					FlxTween.tween(abel, {x: abel.x - 12, "scale.x": -abel.scale.x}, 0.23, {ease: FlxEase.backOut});
				}
				if (abel.x <= bounds.left)
				{
					abel.velocity.x *= -1;
					FlxTween.tween(abel, {x: abel.x + 12, "scale.x": -abel.scale.x}, 0.23, {ease: FlxEase.backOut});
				}
			}
		}
	}

	public static function onDestroy()
	{
		for (abel in abels)
		{
			state.remove(abel, true);
			abel.destroy();
		}
		abels.resize(0);
	}
}