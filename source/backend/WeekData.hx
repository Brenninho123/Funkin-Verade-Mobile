package backend;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
	@:optional var renderPath:String;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';

	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;
	public var renderPath:String = "pausescreen/renders/2Tcholas";

	public var fileName:String;

	public static function createWeekFile():WeekFile {
		var weekFile:WeekFile = {
			songs: [["Bopeebo", "face", [146, 113, 253]], ["Fresh", "face", [146, 113, 253]], ["Dad Battle", "face", [146, 113, 253]]],
			#if BASE_GAME_FILES
			weekCharacters: ['dad', 'bf', 'gf'],
			#else
			weekCharacters: ['bf', 'bf', 'gf'],
			#end
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: ''
		};
		return weekFile;
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile, fileName:String) {
		// here ya go - MiguelItsOut
		for (field in Reflect.fields(weekFile))
			if(Reflect.fields(this).contains(field)) // Reflect.hasField() won't fucking work :/
				Reflect.setProperty(this, field, Reflect.getProperty(weekFile, field));

		this.fileName = fileName;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false)
	{
		weeksList.resize(0);
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getSharedPath()];
		final originalLength:Int = directories.length;

		for (mod in Mods.parseList().enabled) directories.push(Paths.mods('$mod/'));
		#end

		#if MODS_ALLOWED
		final sexList:Array<String> = Mods.mergeAllTextsNamed('weeks/weekList.txt');
		#else
		final sexList:Array<String> = CoolUtil.coolTextFile('weeks/weekList.txt');
		#end
		for (w in sexList)
		{
			#if MODS_ALLOWED
			for (i=>d in directories) addWeek(w, '${d}weeks/$w.json', d, i, originalLength, isStoryMode);
			#else
			addWeek(w, Paths.getSharedPath('weeks/$w.json'), isStoryMode);
			#end
		}
	}

	private static function addWeek(weekToCheck:String, path:String, #if MODS_ALLOWED directory:String, i:Int, originalLength:Int, #end ?forStory:Bool)
	{
		forStory ??= PlayState.isStoryMode;
		if (weeksLoaded.exists(weekToCheck)) return;
		
		var week:WeekFile = getWeekFile(path);
		if (week == null) return;

		var weekFile:WeekData = new WeekData(week, weekToCheck);
		#if MODS_ALLOWED
		if (i >= originalLength)
		{
			weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
		}
		#end

		if ((forStory && !weekFile.hideStoryMode) || (!forStory && !weekFile.hideFreeplay))
		{
			weeksLoaded.set(weekToCheck, weekFile);
			weeksList.push(weekToCheck);
		}
	}

	private static function getWeekFile(path:String):WeekFile {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast tjson.TJSON.parse(rawJson);
		}
		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	//To use on PlayState.hx or Highscore stuff
	public static inline function getWeekFileName():String
	{
		return weeksList[PlayState.storyWeek];
	}

	//Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData
	{
		return weeksLoaded[getWeekFileName()];
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Mods.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			Mods.currentModDirectory = data.folder;
		}
	}
}
