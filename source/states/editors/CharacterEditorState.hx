package states.editors;

import flixel.graphics.FlxGraphic;

import flixel.util.FlxDestroyUtil;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;

import objects.Character;
import objects.HealthIcon;
import objects.Bar;

import states.editors.content.Prompt;
import states.editors.content.PsychJsonPrinter;

#if FLX_DEBUG @:bitmap("assets/images/debugger/cursorCross.png") #end
private class CamCross extends openfl.display.BitmapData {}

class CharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var character:Character;
	var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	var cameraFollowPointer:FlxSprite;
	var isAnimateSprite:Bool = false;

	var silhouettes:FlxSpriteGroup;
	var dadPosition = FlxPoint.weak();
	var bfPosition = FlxPoint.weak();

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

	var healthBar:Bar;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	var anims:Array<AnimArray> = null;
	var animsTxt:FlxText;
	var curAnim = 0;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	var UI_box:PsychUIBox;
	var UI_characterbox:PsychUIBox;

	var unsavedProgress:Bool = false;

	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);

	public function new(char:String = null, goToPlayState:Bool = true)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if(this._char == null) this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		FlxG.sound.music.stop();
		camEditor = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		loadBG();

		silhouettes = new FlxSpriteGroup();
		add(silhouettes);

		var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y, Paths.image('editors/silhouetteDad'));
		dad.antialiasing = ClientPrefs.data.antialiasing;
		dad.active = false;
		dad.offset.set(-4, 1);

		var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350, Paths.image('editors/silhouetteBF'));
		boyfriend.antialiasing = ClientPrefs.data.antialiasing;
		boyfriend.active = false;
		boyfriend.offset.set(-6, 2);

		silhouettes.add(dad);
		silhouettes.add(boyfriend);
		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);
		
		animsTxt = new FlxText(10, 32, 400);
		animsTxt.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		animsTxt.scrollFactor.set();
		animsTxt.cameras = [camHUD];

		addCharacter();

		cameraFollowPointer = new FlxSprite(0, 0, new CamCross(12, 12));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();

		healthBar = new Bar(45, 0, "healthBar", () -> 0.5);
		healthBar.scrollFactor.set();
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character.healthIcon, false, character.healthFruit, false);
		healthIcon.scrollFactor.set();
		healthIcon.cameras = [camHUD];

		fixHealthBar();
		// healthBar.updateBar();

		add(cameraFollowPointer);
		add(healthBar);
		add(healthIcon);
		add(animsTxt);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 20);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.borderSize = 1;
		cameraZoomText.screenCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		addHelpScreen();
		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;

		makeUIMenu();

		updatePointerPos();
		updateHealthBar();
		character.finishAnimation();

		if(ClientPrefs.data.cacheOnGPU) Paths.clearUnusedMemory();

		super.create();
	}

	function addHelpScreen()
	{
		var str:Array<String> = ["CAMERA",
		"E/Q - Camera Zoom In/Out",
		"J/K/L/I - Move Camera",
		"R - Reset Camera Zoom",
		"",
		"CHARACTER",
		"Ctrl + R - Reset Current Offset",
		"Ctrl + C - Copy Current Offset",
		"Ctrl + V - Paste Copied Offset on Current Animation",
		"Ctrl + Z - Undo Last Paste or Reset",
		"W/S - Previous/Next Animation",
		"Space - Replay Animation",
		"Arrow Keys/Mouse & Right Click - Move Offset",
		"A/D - Frame Advance (Back/Forward)",
		"",
		"OTHER",
		"F12 - Toggle Silhouettes",
		"Hold Shift - Move Offsets 10x faster and Camera 4x faster",
		"Hold Control - Move camera 4x slower"];

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height); helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i => txt in str)
		{
			if(txt.length < 1) continue;

			var helpText:FlxText = new FlxText(0, 0, 600, txt, 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length/2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function addCharacter(reload:Bool = false)
	{
		var pos:Int = -1;
		if (character != null)
		{
			pos = members.indexOf(character);
			remove(character);
			character.destroy();
		}

		var isPlayer:Bool = (reload ? character.isPlayer : !predictCharacterIsNotPlayer(_char));
		character = new Character(0, 0, _char, isPlayer);
		if (!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer)
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
			if (check_player != null) check_player.checked = character.isPlayer;
		}
		character.debugMode = true;
		character.missingCharacter = false;

		if (pos > -1) insert(pos, character);
		else add(character);
		updateCharacterPositions();
		reloadAnimList();
		if (healthBar != null && healthIcon != null) updateHealthBar();
	}

	function makeUIMenu()
	{
		UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']);
		UI_box.scrollFactor.set();
		UI_box.cameras = [camHUD];

		UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 350, ['Animations', 'Character']);
		UI_characterbox.scrollFactor.set();
		UI_characterbox.cameras = [camHUD];
		add(UI_characterbox);
		add(UI_box);

		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();

		UI_box.selectedName = 'Settings';
		UI_characterbox.selectedName = 'Character';
	}

	var ghostAlpha:Float = 0.6;
	function addGhostUI()
	{
		var tab_group = UI_box.getTab('Ghost').menu;

		//var hideGhostButton:PsychUIButton = null;
		var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", function() {
			var anim = anims[curAnim];
			if(!character.isAnimationNull())
			{
				var myAnim = anims[curAnim];
				if(!character.isAnimateAtlas)
				{
					ghost.loadGraphic(character.graphic);
					ghost.frames.frames = character.frames.frames;
					ghost.animation.copyFrom(character.animation);
					ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
					ghost.animation.pause();
				}
				else if(myAnim != null) //This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
				{
					if(animateGhost == null) //If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
					{
						animateGhost = new FlxAnimate(ghost.x, ghost.y);
						animateGhost.showPivot = false;
						insert(members.indexOf(ghost), animateGhost);
						animateGhost.active = false;
					}

					if(animateGhost == null || animateGhostImage != character.imageFile)
						Paths.loadAnimateAtlas(animateGhost, character.imageFile);
					
					if(myAnim.indices != null && myAnim.indices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else
						animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					animateGhost.anim.play('anim', true, false, character.atlas.anim.curFrame);
					animateGhost.anim.pause();

					animateGhostImage = character.imageFile;
				}
				
				var spr:FlxSprite = !character.isAnimateAtlas ? ghost : animateGhost;
				if(spr != null)
				{
					spr.setPosition(character.x, character.y);
					spr.antialiasing = character.antialiasing;
					spr.flipX = character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(character.scale.x, character.scale.y);
					spr.updateHitbox();

					spr.offset.set(character.offset.x, character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
					if(otherSpr != null) otherSpr.visible = false;
				}
				/*hideGhostButton.active = true;
				hideGhostButton.alpha = 1;*/
				trace('created ghost image');
			}
		});

		/*hideGhostButton = new PsychUIButton(20 + makeGhostButton.width, makeGhostButton.y, "Hide Ghost", function() {
			ghost.visible = false;
			hideGhostButton.active = false;
			hideGhostButton.alpha = 0.6;
		});
		hideGhostButton.active = false;
		hideGhostButton.alpha = 0.6;*/

		var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
		highlightGhost.onClick = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
			if(animateGhost != null)
			{
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
		};

		var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, makeGhostButton.y + 25, function(v:Float)
		{
			ghostAlpha = v;
			ghost.alpha = ghostAlpha;
			if(animateGhost != null) animateGhost.alpha = ghostAlpha;

		}, ghostAlpha, 0, 1);
		ghostAlphaSlider.label = 'Opacity:';

		tab_group.add(makeGhostButton);
		//tab_group.add(hideGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);
	}

	var check_player:PsychUICheckBox;
	var charDropDown:PsychUIDropDownMenu;
	function addSettingsUI()
	{
		var tab_group = UI_box.getTab('Settings').menu;

		charDropDown = new PsychUIDropDownMenu(15, 30, [''], function(index:Int, intended:String)
		{
			if(intended == null || intended.length < 1) return;

			var characterPath:String = 'characters/$intended.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			if (Paths.fileExists(path, TEXT))
			{
				_char = intended;
				check_player.checked = character.isPlayer;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();
			}
			else
			{
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = _char;

		check_player = new PsychUICheckBox(charDropDown.x, charDropDown.y + 25, "Playable Character", 100);
		check_player.checked = character.isPlayer;
		check_player.onClick = function()
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = !character.flipX;
			updateCharacterPositions();
			updatePointerPos(false);
		};

		var reloadCharacter:PsychUIButton = new PsychUIButton((check_player.x + check_player.width) + 30, charDropDown.y - 20, "Reload Char", function()
		{
			addCharacter(true);
			updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
		});

		var templateCharacter:PsychUIButton = new PsychUIButton(reloadCharacter.x, (reloadCharacter.y + reloadCharacter.height) + 10, "Load Template", function()
		{
			final _template:CharacterFile =
			{
				animations: [
					newAnim('idle', 'idle'),
					newAnim('singLEFT', 'left'),
					newAnim('singDOWN', 'down'),
					newAnim('singUP', 'up'),
					newAnim('singRIGHT', 'right')
				],
				no_antialiasing: false,
				flip_x: false,
				healthicon: null,
				healthfruit: null,
				image: 'characters/bluetooth',
				sing_duration: 4,
				scale: 1,
				healthbar_colors: null,
				fruit_colors: null,
				camera_position: [0, 0],
				position: [0, 0],
				vocals_file: null,
				_editor_isPlayer: false
			};

			character.loadCharacterFile(_template);
			character.missingCharacter = false;
			character.color = FlxColor.WHITE;
			character.alpha = 1;
			reloadAnimList();
			reloadCharacterOptions();
			updateCharacterPositions();
			updatePointerPos();
			reloadCharacterDropDown();
			updateHealthBar();
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;

		var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadCharacter.x, (templateCharacter.y + templateCharacter.height) + 10, "Save Character", saveCharacter);

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(saveCharacterButton);
		tab_group.add(charDropDown);
	}

	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	function addAnimationsUI()
	{
		var tab_group = UI_characterbox.getTab('Animations').menu;

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?", 100);

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
			var anim:AnimArray = character.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {
			var indicesText:String = animationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if(indicesText.length > 0)
			{
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
				if(indicesStr.length > 0)
				{
					for (ind in indicesStr)
					{
						if(ind.contains('-'))
						{
							var splitIndices:Array<String> = ind.split('-');
							var indexStart:Int = Std.parseInt(splitIndices[0]);
							if(Math.isNaN(indexStart) || indexStart < 0) indexStart = 0;
	
							var indexEnd:Int = Std.parseInt(splitIndices[1]);
							if(Math.isNaN(indexEnd) || indexEnd < indexStart) indexEnd = indexStart;
	
							for (index in indexStart...indexEnd+1)
								indices.push(index);
						}
						else
						{
							var index:Int = Std.parseInt(ind);
							if(!Math.isNaN(index) && index > -1)
								indices.push(index);
						}
					}
				}
			}

			var lastAnim:String = (character.animationsArray[curAnim] != null) ? character.animationsArray[curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in character.animationsArray)
				if(animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if(character.hasAnimation(animationInputText.text))
					{
						#if flxanimate
						@:privateAccess if (character.isAnimateAtlas) character.atlas.anim.animsMap.remove(animationInputText.text);
						else #end character.animation.remove(animationInputText.text);
					}
					character.animationsArray.remove(anim);
				}

			var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			character.animationsArray.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character.animationsArray.indexOf(addedAnim)));
			character.playAnim(addedAnim.anim, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(180, animationIndicesInputText.y + 60, "Remove", function() {
			if (character.animationsArray.length == 0)
			{
				trace('Couldn\'t remove animation: No animations found!');
				return;
			}
			final animToRemove:String = animationInputText.text;

			var animCheck:Array<AnimArray> = character.animationsArray.filter((f) -> f.anim == animToRemove);
			trace(animCheck);
			if (animCheck.length != 0)
			{
				character.animationsArray.remove(animCheck[0]);
				character.animOffsets.remove(animToRemove);
			}
			animCheck.resize(0);

			if (!character.hasAnimation(animToRemove))
			{
				trace('Couldn\'t remove animation: Character already doesn\'t have the "${animToRemove}" animation.');
				return;
			}

			final resetAnim:Bool = character.getAnimationName() == animToRemove;
			#if flxanimate
			@:privateAccess if (character.isAnimateAtlas) character.atlas.anim.animsMap.remove(animToRemove);
			else #end character.animation.remove(animToRemove);
			reloadAnimList();

			if (resetAnim)
			{
				curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
				character.playAnim(anims[curAnim].anim, true);
			}
			trace('Removed animation: $animToRemove');
		});
		reloadAnimList();
		animationDropDown.selectedLabel = anims[0].anim ?? "";

		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation Name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Animation Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	var imageInputText:PsychUIInputText;
	var healthIconInputText:PsychUIInputText;
	var fruitInputText:PsychUIInputText;
	var vocalsInputText:PsychUIInputText;

	var singDurationStepper:PsychUINumericStepper;
	var scaleStepper:PsychUINumericStepper;
	var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionCameraXStepper:PsychUINumericStepper;
	var positionCameraYStepper:PsychUINumericStepper;

	var flipXCheckBox:PsychUICheckBox;
	var noAntialiasingCheckBox:PsychUICheckBox;

	var healthColorStepperR:PsychUINumericStepper;
	var healthColorStepperG:PsychUINumericStepper;
	var healthColorStepperB:PsychUINumericStepper;

	var fruitColorStepperR:PsychUINumericStepper;
	var fruitColorStepperG:PsychUINumericStepper;
	var fruitColorStepperB:PsychUINumericStepper;
	
	var fruitAccentStepperR:PsychUINumericStepper;
	var fruitAccentStepperG:PsychUINumericStepper;
	var fruitAccentStepperB:PsychUINumericStepper;

	function addCharacterUI()
	{
		var tab_group = UI_characterbox.getTab('Character').menu;

		imageInputText = new PsychUIInputText(15, 30, 200, character.imageFile);
		var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			var lastAnim = character.getAnimationName();
			character.imageFile = imageInputText.text;
			reloadCharacterImage();
			if(!character.isAnimationNull()) {
				character.playAnim(lastAnim, true);
			}
		});

		healthIconInputText = new PsychUIInputText(imageInputText.x, imageInputText.y + 35, 75, healthIcon.char);
		fruitInputText = new PsychUIInputText((healthIconInputText.x + healthIconInputText.width) + 30, healthIconInputText.y, 75, healthIcon.fruit);

		vocalsInputText = new PsychUIInputText(imageInputText.x, healthIconInputText.y + 35, 75, character.vocalsFile ?? "");
		singDurationStepper = new PsychUINumericStepper(vocalsInputText.x, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new PsychUINumericStepper(imageInputText.x, singDurationStepper.y + 40, 0.1, character.jsonScale ?? 1, 0.05, 10, 2);

		flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = character.flipX;
		if(character.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.onClick = function() {
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
		};

		noAntialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		noAntialiasingCheckBox.onClick = function() {
			character.antialiasing = false;
			if(!noAntialiasingCheckBox.checked && ClientPrefs.data.antialiasing) {
				character.antialiasing = true;
			}
			character.noAntialiasing = noAntialiasingCheckBox.checked;
		};

		positionXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, character.positionArray[0], -9000, 9000, 0);
		positionYStepper = new PsychUINumericStepper(positionXStepper.x + 70, positionXStepper.y, 10, character.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, character.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, character.cameraPosition[1], -9000, 9000, 0);

		healthColorStepperR = new PsychUINumericStepper(singDurationStepper.x, scaleStepper.y + 40, 20, character.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new PsychUINumericStepper(healthColorStepperR.x + healthColorStepperR.width, healthColorStepperR.y, 20, character.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new PsychUINumericStepper(healthColorStepperG.x + healthColorStepperG.width, healthColorStepperR.y, 20, character.healthColorArray[2], 0, 255, 0);

		fruitColorStepperR = new PsychUINumericStepper(healthColorStepperR.x, (healthColorStepperR.y +  healthColorStepperR.height) + 25, 20, character.fruitColorArray[0], 0, 255, 0);
		fruitColorStepperG = new PsychUINumericStepper(fruitColorStepperR.x + fruitColorStepperR.width, fruitColorStepperR.y, 20, character.fruitColorArray[1], 0, 255, 0);
		fruitColorStepperB = new PsychUINumericStepper(healthColorStepperG.x + healthColorStepperG.width, fruitColorStepperR.y, 20, character.fruitColorArray[2], 0, 255, 0);

		fruitAccentStepperR = new PsychUINumericStepper(healthColorStepperR.x, (fruitColorStepperR.y +  fruitColorStepperR.height) + 25, 20, character.fruitAccentColor[0], 0, 255, 0);
		fruitAccentStepperG = new PsychUINumericStepper(fruitColorStepperR.x + fruitColorStepperR.width, fruitAccentStepperR.y, 20, character.fruitAccentColor[1], 0, 255, 0);
		fruitAccentStepperB = new PsychUINumericStepper(healthColorStepperG.x + healthColorStepperG.width, fruitAccentStepperR.y, 20, character.fruitAccentColor[2], 0, 255, 0);

		for (b in [healthColorStepperR.buttonPlus, healthColorStepperR.buttonMinus, fruitColorStepperR.buttonPlus, fruitColorStepperR.buttonMinus, fruitAccentStepperR.buttonPlus, fruitAccentStepperR.buttonMinus]) b.color = FlxColor.RED;
		for (b in [healthColorStepperG.buttonPlus, healthColorStepperG.buttonMinus, fruitColorStepperG.buttonPlus, fruitColorStepperG.buttonMinus, fruitAccentStepperG.buttonPlus, fruitAccentStepperG.buttonMinus]) b.color = FlxColor.LIME;
		for (b in [healthColorStepperB.buttonPlus, healthColorStepperB.buttonMinus, fruitColorStepperB.buttonPlus, fruitColorStepperB.buttonMinus, fruitAccentStepperB.buttonPlus, fruitAccentStepperB.buttonMinus]) b.color = FlxColor.BLUE;

		var decideIconColor:PsychUIButton = new PsychUIButton((healthColorStepperB.x + healthColorStepperB.width) + 35, healthColorStepperB.y, "Use Icon Color", function()
		{
			var coolColor:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(healthIcon.charSprite));
			character.healthColorArray[0] = coolColor.red;
			character.healthColorArray[1] = coolColor.green;
			character.healthColorArray[2] = coolColor.blue;
			updateHealthBar();
		}, null, Math.floor(healthColorStepperB.height));

		tab_group.add(new FlxText(imageInputText.x, imageInputText.y - 18, 100, 'Image file name:'));
		tab_group.add(new FlxText(healthIconInputText.x, healthIconInputText.y - 18, 100, 'Health icon name:'));
		tab_group.add(new FlxText(fruitInputText.x, fruitInputText.y - 18, 100, 'Icon fruit name:'));
		tab_group.add(new FlxText(vocalsInputText.x, vocalsInputText.y - 18, 100, 'Vocals File Postfix:'));
		tab_group.add(new FlxText(singDurationStepper.x, singDurationStepper.y - 18, 120, 'Sing Animation length:'));
		tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 100, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 100, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 100, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 14, 100, 'Health Bar R/G/B:'));
		tab_group.add(new FlxText(fruitColorStepperR.x, fruitColorStepperR.y - 14, 100, 'Icon Fruit R/G/B:'));
		tab_group.add(new FlxText(fruitAccentStepperR.x, fruitAccentStepperR.y - 14, 100, 'Fruit Accent R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(healthIconInputText);
		tab_group.add(fruitInputText);
		tab_group.add(vocalsInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(decideIconColor);
		tab_group.add(fruitColorStepperR);
		tab_group.add(fruitColorStepperG);
		tab_group.add(fruitColorStepperB);
		tab_group.add(fruitAccentStepperR);
		tab_group.add(fruitAccentStepperG);
		tab_group.add(fruitAccentStepperB);
	}

	public function UIEvent(id:String, sender:Dynamic) {
		//trace(id, sender);
		unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT)
		{
			unsavedProgress = true;
			if(sender == healthIconInputText)
			{
				var lastIcon = healthIcon.char;
				healthIcon.changeIcon(healthIconInputText.text, false);
				character.healthIcon = healthIconInputText.text;
				if(lastIcon != healthIcon.char) updatePresence();
			}
			else if (sender == fruitInputText)
			{
				healthIcon.changeFruit(fruitInputText.text, false);
				character.healthFruit = fruitInputText.text;
			}
			else if(sender == vocalsInputText) character.vocalsFile = vocalsInputText.text;
			else if(sender == imageInputText) character.imageFile = imageInputText.text;
		}
		else if(id == PsychUINumericStepper.CHANGE_EVENT)
		{
			if (sender == scaleStepper)
			{
				// reloadCharacterImage();
				character.jsonScale = sender.value;
				character.scale.set(character.jsonScale, character.jsonScale);
				character.updateHitbox();
				updatePointerPos(false);
			}
			else if(sender == positionXStepper)
			{
				character.positionArray[0] = positionXStepper.value;
				updateCharacterPositions();
			}
			else if(sender == positionYStepper)
			{
				character.positionArray[1] = positionYStepper.value;
				updateCharacterPositions();
			}
			else if(sender == singDurationStepper) character.singDuration = singDurationStepper.value;
			else if(sender == positionCameraXStepper)
			{
				character.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if(sender == positionCameraYStepper)
			{
				character.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
			}
			else if(sender == healthColorStepperR)
			{
				character.healthColorArray[0] = Math.round(healthColorStepperR.value);
				updateHealthBar();
			}
			else if(sender == healthColorStepperG)
			{
				character.healthColorArray[1] = Math.round(healthColorStepperG.value);
				updateHealthBar();
			}
			else if(sender == healthColorStepperB)
			{
				character.healthColorArray[2] = Math.round(healthColorStepperB.value);
				updateHealthBar();
			}
			else if(sender == fruitColorStepperR)
			{
				character.fruitColorArray[0] = Math.round(fruitColorStepperR.value);
				updateHealthBar();
			}
			else if(sender == fruitColorStepperG)
			{
				character.fruitColorArray[1] = Math.round(fruitColorStepperG.value);
				updateHealthBar();
			}
			else if(sender == fruitColorStepperB)
			{
				character.fruitColorArray[2] = Math.round(fruitColorStepperB.value);
				updateHealthBar();
			}
			else if(sender == fruitAccentStepperR)
			{
				character.fruitAccentColor[0] = Math.round(fruitAccentStepperR.value);
				updateHealthBar();
			}
			else if(sender == fruitAccentStepperG)
			{
				character.fruitAccentColor[1] = Math.round(fruitAccentStepperG.value);
				updateHealthBar();
			}
			else if(sender == fruitAccentStepperB)
			{
				character.fruitAccentColor[2] = Math.round(fruitAccentStepperB.value);
				updateHealthBar();
			}
		}
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = character.getAnimationName();
		var anims:Array<AnimArray> = character.animationsArray.copy();

		character.atlas = FlxDestroyUtil.destroy(character.atlas);
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		#if flxanimate
		character.isAnimateAtlas = false;
		if(Paths.fileExists('images/' + character.imageFile + '/Animation.json', TEXT))
		{
			character.atlas = new FlxAnimate();
			character.atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(character.atlas, character.imageFile);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${character.imageFile}: $e');
			}
			character.isAnimateAtlas = true;
		}
		else
		#end
		{
			character.frames = Paths.getMultiAtlas(character.imageFile.split(','));
		}

		for (anim in anims) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if(anims.length > 0)
		{
			if(lastAnim != '') character.playAnim(lastAnim, true);
			else character.dance();
		}
	}

	function reloadCharacterOptions() {
		if(UI_characterbox == null) return;

		check_player.checked = character.isPlayer;
		imageInputText.text = character.imageFile;
		healthIconInputText.text = character.healthIcon;
		fruitInputText.text = character.healthFruit;
		vocalsInputText.text = character.vocalsFile != null ? character.vocalsFile : '';
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.jsonScale;
		flipXCheckBox.checked = character.originalFlipX;
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		positionXStepper.value = character.positionArray[0];
		positionYStepper.value = character.positionArray[1];
		positionCameraXStepper.value = character.cameraPosition[0];
		positionCameraYStepper.value = character.cameraPosition[1];
		reloadAnimationDropDown();
		updateHealthBar();
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = [];
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PsychUIInputText.focusOn != null)
		{
			ClientPrefs.toggleVolumeKeys(false);
			return;
		}
		ClientPrefs.toggleVolumeKeys(true);

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		if(lastZoom != FlxG.camera.zoom) cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

		// CHARACTER CONTROLS
		if (anims.length > 1)
		{
			var changedAnim:Bool = false;
			if (FlxG.keys.justPressed.W)
			{
				curAnim--;
				changedAnim = true;
			}
			if (FlxG.keys.justPressed.S)
			{
				curAnim++;
				changedAnim = true;
			}

			if (changedAnim)
			{
				undoOffsets.resize(0);
				curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
				character.playAnim(anims[curAnim].anim, true);
				updateText();
			}
		}

		var changedOffset = false;
		var moveKeysP:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
		var moveKeys:Array<Bool> = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
		if (moveKeysP.contains(true))
		{
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}
		moveKeysP.resize(0);

		if (moveKeys.contains(true))
		{
			holdingArrowsTime += elapsed;
			if (holdingArrowsTime > 0.6)
			{
				holdingArrowsElapsed += elapsed;
				while (holdingArrowsElapsed > (1 / FlxG.updateFramerate))
				{
					character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1 / FlxG.updateFramerate);
					changedOffset = true;
				}
			}
		}
		else holdingArrowsTime = 0;
		moveKeys.resize(0);

		if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaViewX != 0 || FlxG.mouse.deltaViewY != 0))
		{
			character.offset.x -= FlxG.mouse.deltaViewX;
			character.offset.y -= FlxG.mouse.deltaViewY;
			changedOffset = true;
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.C)
			{
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
			}
			if (FlxG.keys.justPressed.V)
			{
				undoOffsets = copiedOffset.copy();
				character.offset.set(copiedOffset[0], copiedOffset[1]);
				changedOffset = true;
			}
			if (FlxG.keys.justPressed.R)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set();
				changedOffset = true;
			}
			if (FlxG.keys.justPressed.Z && undoOffsets.length != 0)
			{
				character.offset.set(undoOffsets[0], undoOffsets[1]);
				changedOffset = true;
			}
		}

		final anim:AnimArray = anims[curAnim];
		if (changedOffset && anim != null && anim.offsets != null)
		{
			anim.offsets[0] = Math.round(character.offset.x);
			anim.offsets[1] = Math.round(character.offset.y);

			character.addOffset(anim.anim, character.offset.x, character.offset.y);
			updateText();
		}

		var txt:String = 'ERROR: No Animation Found';
		var clr:FlxColor = FlxColor.RED;
		if (!character.isAnimationNull())
		{
			if (FlxG.keys.pressed.A || FlxG.keys.pressed.D)
			{
				holdingFrameTime += elapsed;
				if (holdingFrameTime > 0.5) holdingFrameElapsed += elapsed;
			}
			else holdingFrameTime = 0;

			if (FlxG.keys.justPressed.SPACE) character.playAnim(character.getAnimationName(), true);

			var frames:Int = -1;
			var length:Int = -1;
			#if flxanimate
			if (character.isAnimateAtlas)
			{
				frames = character.atlas.anim.curFrame;
				length = character.atlas.anim.length - 1;
			}
			else
			#end
			{
				frames = character.animation.curAnim.curFrame;
				length = character.animation.curAnim.numFrames - 1;
			}

			if (length >= 0)
			{
				if ((FlxG.keys.justPressed.A || FlxG.keys.justPressed.D) || holdingFrameTime > 0.5)
				{
					final isLeft:Bool = (holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A;
					character.animPaused = true;
	
					if (holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
					{
						frames = FlxMath.wrap(frames + Math.round(isLeft ? -shiftMult : shiftMult), 0, length);
						#if flxanimate
						if (character.isAnimateAtlas) character.atlas.anim.curFrame = frames;
						else #end character.animation.curAnim.curFrame = frames;
						holdingFrameElapsed -= 0.1;
					}
				}
	
				txt = 'Frames: $frames/$length';
				clr = FlxColor.WHITE;
			}
		}
		if (txt != frameAdvanceText.text) frameAdvanceText.text = txt;
		if (clr != frameAdvanceText.color) frameAdvanceText.color = clr;

		if (FlxG.keys.justPressed.F12) silhouettes.visible = !silhouettes.visible;

		if (FlxG.keys.justPressed.F1 || (helpBg.visible && controls.BACK))
		{
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
		}
		else if (controls.BACK)
		{
			if (!_goToPlayState)
			{
				if (!unsavedProgress) FlxG.switchState(() -> new MainMenuState());
				else openSubState(new ExitConfirmationPrompt());
			}
			else FlxG.switchState(() -> new PlayState());
		}
	}

	inline function loadBG()
	{
		camEditor.bgColor = 0xFF666666;
		dadPosition.set(100, 100);
		bfPosition.set(770, 100);
	}

	inline function updatePointerPos(?snap:Bool = true)
	{
		if (character == null || cameraFollowPointer == null) return;
		final offX:Float = !character.isPlayer ? (character.getMidpoint().x + 150) + character.cameraPosition[0] : (character.getMidpoint().x - 100) - character.cameraPosition[0];
		final offY:Float = (character.getMidpoint().y - 100) + character.cameraPosition[1];

		cameraFollowPointer.setPosition(offX, offY);
		if (snap) FlxG.camera.scroll.set(cameraFollowPointer.getMidpoint().x - FlxG.width / 2, cameraFollowPointer.getMidpoint().y - FlxG.height / 2);
	}

	inline function fixHealthBar()
	{
		healthBar.bg.scale.set(0.73, 0.73); healthBar.bg.updateHitbox();

		healthBar.barWidth = 552;
		for (b in [healthBar.leftBar, healthBar.rightBar])
		{
			b.loadGraphic(Paths.image('healthBar_bar'));
			b.antialiasing = true;
			b.offset.set(55, -5);
		}
		healthBar.barOffset.set(-2, -1);
		healthBar.leftToRight = true;
		healthBar.y = (FlxG.height - healthBar.height) - healthBar.x;

		// Posição igual de PlayState
		healthIcon.scale.set(1.2, 1.2);
		healthIcon.scale.set(1, 1);
		healthIcon.setPosition(healthBar.x, healthBar.y - 36); // 36
	}

	inline function updateHealthBar()
	{
		healthColorStepperR.value = character.healthColorArray[0];
		healthColorStepperG.value = character.healthColorArray[1];
		healthColorStepperB.value = character.healthColorArray[2];
		healthBar.setColors(FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]), FlxColor.BLACK);

		healthIcon.changeIcon(character.healthIcon, false);
		healthIcon.changeFruit(character.healthFruit);

		fruitColorStepperR.value = character.fruitColorArray[0]; fruitAccentStepperR.value = character.fruitAccentColor[0];
		fruitColorStepperG.value = character.fruitColorArray[1]; fruitAccentStepperG.value = character.fruitAccentColor[1];
		fruitColorStepperB.value = character.fruitColorArray[2]; fruitAccentStepperB.value = character.fruitAccentColor[2];
		healthIcon.fruitRGB.r = FlxColor.fromRGB(character.fruitColorArray[0], character.fruitColorArray[1], character.fruitColorArray[2]);
		healthIcon.fruitRGB.b = FlxColor.fromRGB(character.fruitAccentColor[0], character.fruitAccentColor[1], character.fruitAccentColor[2]);

		updatePresence();
	}

	inline function updatePresence()
	{
		#if DISCORD_ALLOWED DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.char); #end
	}

	inline function reloadAnimList()
	{
		anims = character.animationsArray;
		if (anims.length > 0) character.playAnim(anims[0].anim, true);
		curAnim = 0;

		updateText();
		if (animationDropDown != null) reloadAnimationDropDown();
	}

	inline function updateText()
	{
		animsTxt.removeFormat(selectedFormat);

		var intendText:String = '';
		for (i=>anim in anims)
		{
			if (i > 0) intendText += '\n';
			final selectedIndex:Int = intendText.length;

			intendText += '${anim.anim}: ${anim.offsets}';
			if (i == curAnim) animsTxt.addFormat(selectedFormat, selectedIndex, intendText.length);
		}
		animsTxt.text = intendText;
	}

	inline function updateCharacterPositions()
	{
		if ((!character?.editorIsPlayer || !character?.isPlayer) || predictCharacterIsNotPlayer(_char)) character.setPosition(dadPosition.x, dadPosition.y);
		else character.setPosition(bfPosition.x, bfPosition.y);

		character.x += character.positionArray[0];
		character.y += character.positionArray[1];
		updatePointerPos(false);
	}

	inline function predictCharacterIsNotPlayer(name:String):Bool
	{
		return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-playable') && !name.endsWith('-dead')) ||
				name.endsWith('-opponent') || name.startsWith('gf-') || name.endsWith('-gf') || name == 'gf';
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		#if flxanimate
		if (character.isAnimateAtlas)
		{
			if(indices != null && indices.length > 0)
				character.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				character.atlas.anim.addBySymbol(anim, name, fps, loop);
		}
		else
		#end
		{
			if(indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				character.animation.addByPrefix(anim, name, fps, loop);
		}

		if (!character.animOffsets.exists(anim)) character.addOffset(anim);
	}

	inline function newAnim(anim:String, name:String):AnimArray
	{
		return {
			offsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	var characterList:Array<String> = [];
	function reloadCharacterDropDown()
	{
		characterList.resize(0);
		
		#if MODS_ALLOWED
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
		#else
		final folder:String = Paths.getSharedPath('characters/');
		#end
			for (file in FileSystem.readDirectory(folder))
			{
				final filename:String = file.substr(0, file.length - '.json'.length);
				if (!file.toLowerCase().endsWith('.json') || characterList.contains(filename)) continue;

				characterList.push(filename);
			}

		if (characterList.length == 0) characterList.push('NO CHARACTERS');
		charDropDown.list = characterList;
		charDropDown.selectedLabel = _char;
	}

	function reloadAnimationDropDown()
	{
		var animList:Array<String> = [for (a in anims) a.anim];
		if (animList.length == 0) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.list = animList;
	}

	// save
	var _file:FileReference;
	function onSaveComplete(_)
	{
		if (_file == null) return;
		unsavedProgress = false;

		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_)
	{
		if (_file == null) return;

		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_)
	{
		if (_file == null) return;

		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter()
	{
		if (_file != null) return;

		var json:CharacterFile = 
		{
			animations: character.animationsArray,
			image: character.imageFile,
			scale: character.jsonScale,
			sing_duration: character.singDuration,
			healthicon: character.healthIcon,
			healthfruit: character.healthFruit,

			position:	character.positionArray,
			camera_position: character.cameraPosition,

			flip_x: character.originalFlipX,
			no_antialiasing: character.noAntialiasing,
			healthbar_colors: character.healthColorArray,
			fruit_colors: {color: character.fruitColorArray, accent: character.fruitAccentColor},
			vocals_file: character.vocalsFile,
			_editor_isPlayer: character.isPlayer
		};

		var data:String = PsychJsonPrinter.print(json, ['offsets', 'position', 'healthbar_colors', 'camera_position', 'indices', 'color', 'accent']);
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
		}
	}
}
