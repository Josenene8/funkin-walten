package;

import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import openfl.filters.ShaderFilter;
import Shaders;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import flash.system.System;

#if sys
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['Get Better!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Come on now', 0.5], //From 40% to 49%
		['Uhh', 0.6], //From 50% to 59%
		['Decent', 0.69], //From 60% to 68%
		['nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Jack would be proud!', 0.9], //From 80% to 89%
		['Fantastic!', 1], //From 90% to 99%
		['Fabulous!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	
	public var shaderUpdates:Array<Float->Void> = [];
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];
	
	var billyJumpscare:FlxSprite;
	var billyJumpscare2:FlxSprite;
	var billyJumpscare3:FlxSprite;
	var billyJumpscare4:FlxSprite;
	
	var jumpScare:FlxSprite;
	var blackScreen:FlxSprite;
	var rosieScreen:FlxSprite;
	var blurscreen:FlxSprite;


	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var jackBG:BGSprite;
	var halloweenWhite:BGSprite;
	var billyBG:BGSprite;
	var wiresBG:BGSprite;
	var houseBG:BGSprite;
	var sha1BG:BGSprite;
	var sha2BG:BGSprite;
	var sha3BG:BGSprite;
	var rosieBodyBG:BGSprite;
	var gfBG:BGSprite;
	var BrianBG:BGSprite;
	var blackBG:BGSprite;
	var whiteBG:BGSprite;
	var bouncingkidsBG:BGSprite;
	var bouncingkids2BG:BGSprite;
	var bannyroomBG:BGSprite;
	var banny1BG:BGSprite;
	var banny2BG:BGSprite;
	var banny3BG:BGSprite;
	var bannysadBG:BGSprite;
	var jollyBG:BGSprite;
	var redBG:BGSprite;
	var toyshopBG:BGSprite;
	var toyshop2BG:BGSprite;
	var toyshop3BG:BGSprite;
	var toyshop4BG:BGSprite;
	var BonFriends:BGSprite;
	var BonSofa:BGSprite;
	var DJ:BGSprite;
	var BoozooDance:BGSprite;
	var BillyDance:BGSprite;
	
	//Lucky You Text
	var text1:BGSprite;
	var text2:BGSprite;
	var text3:BGSprite;
	var text4:BGSprite;
	var text5:BGSprite;
	
	//Lucky You Flashbacks
	var flashback1BG:BGSprite;
	var flashback2BG:BGSprite;
	var flashback3BG:BGSprite;
	var flashback4BG:BGSprite;
	var flashback5BG:BGSprite;
	var flashback6BG:BGSprite;
	var flashback7BG:BGSprite;
	var flashback8BG:BGSprite;
	var flashback9BG:BGSprite;
	var flashback10BG:BGSprite;
	var flashback11BG:BGSprite;
	var flashback12BG:BGSprite;

	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:ModchartSprite;
	var blammedLightsBlackTween:FlxTween;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;
	var trainSound:FlxSound;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var bottomBoppersup:BGSprite;
	var bottomBopperstalk:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	//Character Select
	var charSelection:Int = CharSelectState.curSelected;
	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	override public function create()
	{
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		Achievements.loadAchievements();

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = PlayState.SONG.stage;
		//trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				default:
					curStage = 'stage';
			}
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
			
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100]
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'spooky': //Week 1
					halloweenBG = new BGSprite('halloween_bg', -250, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				
				add(halloweenBG);
				
					//BonSofa = new FlxSprite(-400, 0);
							//BonSofa.frames = Paths.getSparrowAtlas('Bon_Friends');
							//BonSofa.animation.addByPrefix('SofaMove', 'halloweem bg copy 20', 24);
							///BonSofa.setGraphicSize(Std.int(BonSofa.width * 0.7));
							//BonSofa.antialiasing = true;
							//BonSofa.scrollFactor.set(0.82, 0.82);
							//add(BonSofa);
				
			case 'k9': //Week 1
					halloweenBG = new BGSprite('k9_bg', -250, -100, ['k9 bg0', 'halloweem bg lightning strike']);
					wiresBG = new BGSprite('k9_bg2', -250, -100, ['k9 bg20', 'halloweem bg lightning strike']);
				add(halloweenBG);
				add(wiresBG);
				
				case 'k92': //Week 2
					halloweenBG = new BGSprite('k9_bg', -250, -100, ['k9 bg0', 'halloweem bg lightning strike']);
					wiresBG = new BGSprite('k9_bg2', -250, -100, ['k9 bg20', 'halloweem bg lightning strike']);
					billyBG = new BGSprite('k9_bg3', -250, -100, ['Billy K90', 'billyidle']);
					billyBG.animation.addByPrefix('hi', 'Billy K9 20', 24, false);
				add(halloweenBG);
				add(wiresBG);
				add(billyBG);
				
			case 'littlebonroom': //Week 1
				
					halloweenBG = new BGSprite('halloween_bg', -250, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
					
				add(halloweenBG);
				var repositionShit = -200;
				
					BonSofa = new BGSprite('Bon_Friends', repositionShit, -40, ['halloweem bg copy 2']);
					BonSofa.updateHitbox();
					add(BonSofa);
					BonSofa.antialiasing = false;
				
				add(BonSofa);
				jackBG = new BGSprite('jack_bg', -250, -100, ['jack bg0', 'halloweem bg lightning strike']);
				add(jackBG);
				jackBG.alpha = 0;
				
				case 'littlebonroomremix': //Week 1
				//if(!ClientPrefs.lowQuality) {
				
					halloweenBG = new BGSprite('halloween_bg', -250, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
					houseBG = new BGSprite('remix_bg', -510, 0, ['remix bg0', 'halloweem bg lightning strike']);
				
				add(halloweenBG);
				add(houseBG);
				var repositionShit = -200;
					BonSofa = new BGSprite('Bon_Friends', repositionShit, -40, ['halloweem bg copy 2']);
					BonSofa.updateHitbox();
					add(BonSofa);
					BonSofa.antialiasing = false;
				
				add(BonSofa);
				//BonSofa.alpha = 0;
				
				
				var repositionShit = 350;
					DJ = new BGSprite('Sha_Remix_DJ_FNF_assets', repositionShit, 275, ['DJ Sha Dancing Beat']);
					DJ.updateHitbox();
					add(DJ);
					DJ.antialiasing = false;
				
				add(DJ);
				
				var repositionShit = -250;
					BillyDance = new BGSprite('BillyRemix', repositionShit, 320, ['Billy Dance']);
					BillyDance.updateHitbox();
					add(BillyDance);
					BillyDance.antialiasing = false;
					
				add(BillyDance);
				
				var repositionShit = 1020;
					BoozooDance = new BGSprite('BoozooRemix', repositionShit, 215, ['Boozoo Dance 1']);
					BoozooDance.updateHitbox();
					add(BoozooDance);
					BoozooDance.antialiasing = false;
				
				add(BoozooDance);
				
				jackBG = new BGSprite('jack_bg', -250, -100, ['jack bg0', 'halloweem bg lightning strike']);
				add(jackBG);
				jackBG.alpha = 0;
				
				DJ.alpha = 0;
				houseBG.alpha = 0;
				BillyDance.alpha = 0;
				BoozooDance.alpha = 0;
				
				
				case 'promostage': //Week 1
					halloweenBG = new BGSprite('stage_bg', -250, -100, ['stage bg0', 'halloweem bg lightning strike']);
					houseBG = new BGSprite('stage_2_bg', -420, -100, ['stage2 bg20', 'halloweem bg lightning strike']);
					
				add(halloweenBG);
				add(houseBG);
				
			case 'mysterioushouse': //Week A
					GameOverSubstate.deathSoundName = 'fnf_loss_sfx-mh';
				GameOverSubstate.loopSoundName = 'gameOver-mh';
				GameOverSubstate.endSoundName = 'gameOverEnd-mh';
				GameOverSubstate.characterName = 'bf-mh-dead';
					halloweenBG = new BGSprite('house_bg', -250, -100, ['house bg0', 'halloweem bg lightning strike']);
					houseBG = new BGSprite('house_bg2', -250, -100, ['house bg20', 'halloweem bg lightning strike']);
				add(halloweenBG);
				add(houseBG);
				
			case 'mhoutside': //Week A
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-jb';
				GameOverSubstate.loopSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.endSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.characterName = 'bf-jb-dead';
					halloweenBG = new BGSprite('mhoutside_bg', -250, -100, ['outside bg0', 'halloweem bg lightning strike']);
				add(halloweenBG);
				
			case 'mhdark': //Week A
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-mh';
				GameOverSubstate.loopSoundName = 'gameOver-mh';
				GameOverSubstate.endSoundName = 'gameOverEnd-mh';
				GameOverSubstate.characterName = 'bf-mh-dead';
					halloweenBG = new BGSprite('dark_bg', -250, -100, ['dark bg0', 'halloweem bg lightning strike']);
					houseBG = new BGSprite('dark_2_bg', -250, -100, ['dark 2 bg20', 'halloweem bg lightning strike']);
					gfBG = new BGSprite('dark_3_bg', -250, -100, ['dark 3 bg20', 'halloweem bg lightning strike']);
				add(halloweenBG);
				add(houseBG);
				add(gfBG);
				
			case 'quantum': //White
					halloweenBG = new BGSprite('quantum_bg', -4650, -50, ['Background art0']);
					halloweenBG.setGraphicSize(Std.int(halloweenBG.width * 1));
				halloweenBG.updateHitbox();
				add(halloweenBG);
				
				case 'toyshop': //Week B
					GameOverSubstate.deathSoundName = 'fnf_loss_sfx-bg';
				GameOverSubstate.loopSoundName = 'gameOver-bg';
				GameOverSubstate.endSoundName = 'gameOverEnd-bg';
				GameOverSubstate.characterName = 'bf-bg-dead';
				toyshop3BG = new BGSprite('toyshop_bg_3', 400, -250, ['JollyAndSadAnim Intro0']);
				toyshop3BG.animation.addByPrefix('intro', 'JollyAndSadAnim Intro0', 24, false);
				toyshop2BG = new BGSprite('toyshop_bg_3', 400, -250, ['JollyAndSadAnim0']);
				toyshop4BG = new BGSprite('toyshop_bg_2-2', -200, -200, ['JollyAndSad Bye0']);
				toyshop4BG.animation.addByPrefix('bye', 'JollyAndSad Bye0', 24, false);
				bottomBoppers = new BGSprite('toyshop_bg_2', -200, -200, ['JollyAndSad0']);
					toyshopBG = new BGSprite('toyshop_bg', -200, -200, ['toyshop bg0', 'halloweem bg lightning strike']);
					var repositionShit = 1000;
				//bottomBoppers = new BGSprite('BoozooBGUp', repositionShit, 185, ['B Idle  Up0']);
				//bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				//bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
					toyshop3BG.updateHitbox();
				add(toyshop3BG);
				
				toyshop2BG.updateHitbox();
				add(toyshop2BG);
				
				toyshop4BG.updateHitbox();
				add(toyshop4BG);
				
				bottomBoppers.updateHitbox();
				add(bottomBoppers);
				
				add(toyshopBG);
				toyshop2BG.antialiasing = false;
				toyshop3BG.antialiasing = false;
				toyshop4BG.antialiasing = false;
				bottomBoppers.antialiasing = false;
				toyshop2BG.alpha = 0;
				toyshop3BG.alpha = 0;
				toyshop4BG.alpha = 0;
				
				case 'jollyroom': //Week B
					GameOverSubstate.deathSoundName = 'fnf_loss_sfx-bg';
				GameOverSubstate.loopSoundName = 'gameOver-bg';
				GameOverSubstate.endSoundName = 'gameOverEnd-bg';
				GameOverSubstate.characterName = 'bf-bg-dead';
					jollyBG = new BGSprite('jolly_bg', -200, -100, ['jolly bg0', 'halloweem bg lightning strike']);
					redBG = new BGSprite('RED', -250, -200, ['red bg0', 'halloweem bg lightning strike']);
					var repositionShit = 1000;
				bottomBoppers = new BGSprite('BoozooBGUp', repositionShit, 185, ['B Idle  Up0']);
				//bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(jollyBG);
				add(redBG);
				add(bottomBoppers);
				redBG.alpha = 0;
				bottomBoppers.antialiasing = false;
				
				case 'sadroom': //Week B
					GameOverSubstate.deathSoundName = 'fnf_loss_sfx-bg';
				GameOverSubstate.loopSoundName = 'gameOver-bg';
				GameOverSubstate.endSoundName = 'gameOverEnd-bg';
				GameOverSubstate.characterName = 'bf-bg-dead';
					jollyBG = new BGSprite('black_bg', -250, -100, ['black bg0', 'halloweem bg lightning strike']);
					var repositionShit = 1000;
				bottomBoppers = new BGSprite('BoozooBG', repositionShit, 185, ['B Idle 0']);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				
				bottomBoppersup = new BGSprite('BoozooBGUp', repositionShit, 185, ['B Idle  Up0']);
				bottomBoppersup.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppersup.updateHitbox();
				
				bottomBopperstalk = new BGSprite('BoozooBG', repositionShit, 185, ['B Idle 0']);
				bottomBopperstalk.animation.addByPrefix('talk', 'B Talk0', 24, false);
				bottomBopperstalk.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBopperstalk.updateHitbox();
					
				add(jollyBG);
				add(bottomBoppers);
				add(bottomBoppersup);
				add(bottomBopperstalk);
				bottomBoppers.antialiasing = false;
				bottomBoppersup.antialiasing = false;
				bottomBopperstalk.antialiasing = false;
				
				bottomBopperstalk.alpha = 0;
				bottomBoppersup.alpha = 0;
				case 'black-minutos': //Week 1
	GameOverSubstate.deathSoundName = 'gameOver-minutos';
				GameOverSubstate.loopSoundName = 'gameOverloop-minutos';
				GameOverSubstate.endSoundName = 'gameOverloop-minutos';
				GameOverSubstate.characterName = 'jc-dead';
					halloweenBG = new BGSprite('minutos_bg', -250, -100, ['minutos bg0', 'halloweem bg lightning strike']);
				add(halloweenBG);
				//add(houseBG);

case 'black': //Week 1
					halloweenBG = new BGSprite('black_bg', -250, -100, ['black bg0', 'halloweem bg lightning strike']);

				add(halloweenBG);
				
case 'black-rocket': //Week 1
					halloweenBG = new BGSprite('black_bg', -250, -100, ['black bg0', 'halloweem bg lightning strike']);

				add(halloweenBG);
				
case 'bucket': //Week 1
					halloweenBG = new BGSprite('bucket_bg', -250, -100, ['bucket bg0', 'halloweem bg lightning strike']);

				add(halloweenBG);
				
case 'lucky': //Lucky You
	
	GameOverSubstate.deathSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.loopSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.endSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.characterName = 'bfdisappear';
		
					flashback1BG = new BGSprite('luckyyou/flashback_1', -250, -100, ['lucky 1 bg0', 'halloweem bg lightning strike']);
					flashback2BG = new BGSprite('luckyyou/flashback_2', -250, -100, ['lucky 2 bg0', 'halloweem bg lightning strike']);
					flashback3BG = new BGSprite('luckyyou/flashback_3', -250, -100, ['lucky 3 bg0', 'halloweem bg lightning strike']);
					flashback4BG = new BGSprite('luckyyou/flashback_4', -250, -100, ['lucky 4 bg0', 'halloweem bg lightning strike']);
					flashback5BG = new BGSprite('luckyyou/flashback_5', -250, -100, ['lucky 5 bg0', 'halloweem bg lightning strike']);
					flashback6BG = new BGSprite('luckyyou/flashback_6', -250, -100, ['lucky 6 bg0', 'halloweem bg lightning strike']);
					flashback7BG = new BGSprite('luckyyou/flashback_7', -250, -100, ['lucky 7 bg0', 'halloweem bg lightning strike']);
					flashback8BG = new BGSprite('luckyyou/flashback_8', -250, -100, ['lucky 8 bg0', 'halloweem bg lightning strike']);
					flashback9BG = new BGSprite('luckyyou/flashback_9', -250, -100, ['lucky 9 bg0', 'halloweem bg lightning strike']);
					flashback10BG = new BGSprite('luckyyou/flashback_10', -250, -100, ['lucky 10 bg0', 'halloweem bg lightning strike']);
					flashback11BG = new BGSprite('luckyyou/flashback_11', -250, -100, ['lucky 11 bg0', 'halloweem bg lightning strike']);
					flashback12BG = new BGSprite('luckyyou/flashback_12', -250, -100, ['lucky 12 bg0', 'halloweem bg lightning strike']);
					halloweenBG = new BGSprite('lucky_bg', -250, -100, ['lucky bg0', 'halloweem bg lightning strike']);



				add(halloweenBG);
				add(flashback1BG);
				add(flashback2BG);
				add(flashback3BG);
				add(flashback4BG);
				add(flashback5BG);
				add(flashback6BG);
				add(flashback7BG);
				add(flashback8BG);
				add(flashback9BG);
				add(flashback10BG);
				add(flashback11BG);
				add(flashback12BG);
				
				
				
				flashback1BG.alpha = 0;
					flashback2BG.alpha = 0;
					flashback3BG.alpha = 0;
					flashback4BG.alpha = 0;
					flashback5BG.alpha = 0;
					flashback6BG.alpha = 0;
					flashback7BG.alpha = 0;
					flashback8BG.alpha = 0;
					flashback9BG.alpha = 0;
					flashback10BG.alpha = 0;
					flashback11BG.alpha = 0;
					flashback12BG.alpha = 0;
				//add(houseBG);
				
				case 'forest': //Week 1
				
					halloweenBG = new BGSprite('carrotbon_bg', -200, -100, ['carrotbon bg0', 'halloweem bg lightning strike']);
					bouncingkidsBG = new BGSprite('carrotbon_bg_2', -200, 100, ['Bouncing Food', 'halloweem bg lightning strike']);
					bouncingkids2BG = new BGSprite('carrotbon_bg_2', -200, -300, ['Bouncing Food', 'halloweem bg lightning strike']);
					bouncingkids2BG.animation.addByPrefix('land', 'Bouncing Food Land0', 24, false);
					
				add(halloweenBG);
				//add(bouncingkidsBG);
				//bouncingkidsBG.alpha = 0;
				//bouncingkidsBG.antialiasing = false;
				//add(bouncingkids2BG);
				//bouncingkids2BG.alpha = 0;
				//bouncingkids2BG.antialiasing = false;
				
				case 'relocateroom': //Week 2
					halloweenBG = new BGSprite('relocate_bg', -250, -100, ['relocate bg0', 'halloweem bg lightning strike']);
					bouncingkidsBG = new BGSprite('relocate_kids_bg', -150, 400, ['Bouncing Kids0', 'halloweem bg lightning strike']);
var repositionShit = 350;
				bottomBoppers = new BGSprite('Relocate_Felix', repositionShit, 200, ['FELIX MOVE0']);
				//bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
					
				add(halloweenBG);
				add(bouncingkidsBG);
				//add(bottomBoppers);
				bouncingkidsBG.antialiasing = false;
				bottomBoppers.antialiasing = false;
				
				case 'bannyreprogram': //Week 2
					bannyroomBG = new BGSprite('bannyk9_bg', -250, -100, ['bannyk9 bg0', 'halloweem bg lightning strike']);
					banny1BG = new BGSprite('black_bg', -250, -100, ['black bg0', 'halloweem bg lightning strike']);
					whiteBG = new BGSprite('white_bg', -400, -100, ['white bg0', 'halloweem bg lightning strike']);
					
				add(bannyroomBG);
				add(banny1BG);
				add(whiteBG);
				//add(rosieBodyBG);
				bannyroomBG.alpha = 0;
				whiteBG.alpha = 1;
				banny1BG.alpha = 0;
				//rosieBodyBG.alpha = 0;
				
				
				case 'techsptroom': //Week 2
					blackBG = new BGSprite('black_bg', -250, -100, ['black bg0', 'halloweem bg lightning strike']);
					halloweenBG = new BGSprite('sha_bg', -250, -100, ['sha bg0', 'halloweem bg lightning strike']);
					houseBG = new BGSprite('sha_2_bg', -250, -100, ['sha bg0', 'halloweem bg lightning strike']);
					sha1BG = new BGSprite('sha_2_bg2', -250, -100, ['sha bg20', 'halloweem bg lightning strike']);
					sha2BG = new BGSprite('sha_2_bg3', -250, -100, ['sha bg30', 'halloweem bg lightning strike']);
					sha3BG = new BGSprite('sha_2_bg_shadow', -250, -100, ['sha bg shadow0', 'halloweem bg lightning strike']);
					//rosieBodyBG = new BGSprite('RosieBody', -250, -100, ['rosie body bg0', 'halloweem bg lightning strike']);
				
				add(blackBG);
				add(halloweenBG);
				add(houseBG);
				add(sha1BG);
				add(sha2BG);
				add(sha3BG);
				//add(rosieBodyBG);
				sha1BG.alpha = 0;
				sha2BG.alpha = 0;
				sha3BG.alpha = 0;
				//rosieBodyBG.alpha = 0;
				
				case 'white': //White
					whiteBG = new BGSprite('white_bg', -250, -100, ['white bg0', 'halloweem bg lightning strike']);

					
				add(whiteBG);
				
					case 'whitespin': //Spin
						GameOverSubstate.deathSoundName = 'gameOver-spin';
				GameOverSubstate.loopSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.endSoundName = 'gameOverEnd-spin';
				GameOverSubstate.characterName = 'bonspindeath';
					whiteBG = new BGSprite('white_bg', -250, -100, ['white bg0', 'halloweem bg lightning strike']);

					
				add(whiteBG);
				
			case 'caveplush': //Bon Plush
				GameOverSubstate.characterName = 'bf-plush-dead';
				GameOverSubstate.deathSoundName = 'gameOver-plush';
				GameOverSubstate.loopSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.endSoundName = 'gameOverloop-completesilence';
					halloweenBG = new BGSprite('cave_bg', -250, -100, ['cave bg0', 'halloweem bg lightning strike']);
					var repositionShit = -270;
				banny1BG = new BGSprite('Banny_Hold', repositionShit, 165, ['BANNY HOLD0']);
				banny2BG = new BGSprite('Banny_Hold', repositionShit, 165, ['BANNY SAD0']);
				banny3BG = new BGSprite('Banny_Hold', repositionShit, 165, ['BANNY SCREAM0']);
				blackBG = new BGSprite('black', -200, -100);
				
				//bannysadBG = new BGSprite('bannysad', -250, -100, ['banny bg0', 'halloweem bg lightning strike']);
				//bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				banny1BG.setGraphicSize(Std.int(banny1BG.width * 1));
				banny1BG.updateHitbox();
				banny2BG.setGraphicSize(Std.int(banny2BG.width * 1));
				banny2BG.updateHitbox();
				banny3BG.setGraphicSize(Std.int(banny3BG.width * 1.2));
				banny3BG.updateHitbox();
					
				add(halloweenBG);
				add(banny1BG);
				add(banny2BG);
				add(banny3BG);
				add(blackBG);
				//add(bannysadBG);
				banny1BG.antialiasing = false;
				banny2BG.antialiasing = false;
				banny3BG.antialiasing = false;
				banny1BG.alpha = 1;
				banny2BG.alpha = 0;
				banny3BG.alpha = 0;
					//bannysadBG.alpha = 0;
				
			case 'philly': //Week 3
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}
				
				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyCityLights = new FlxTypedGroup<BGSprite>();
				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:BGSprite = new BGSprite('philly/win' + i, city.x, city.y, 0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					phillyCityLights.add(light);
				}

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				CoolUtil.precacheSound('train_passes');
				FlxG.sound.list.add(trainSound);

				var street:BGSprite = new BGSprite('philly/street', -40, 50);
				add(street);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					CoolUtil.precacheSound('dancerdeath');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				CoolUtil.precacheSound('Lights_Shut_off');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				/*if(!ClientPrefs.lowQuality) { //Does this even do something?
					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				}*/
				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(boyfriendGroup);
		
		if(curStage == 'spooky') {
			add(halloweenWhite);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if(curStage == 'philly') {
			phillyCityLightsEvent = new FlxTypedGroup<BGSprite>();
			for (i in 0...5)
			{
				var light:BGSprite = new BGSprite('philly/win' + i, -10, 0, 0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				phillyCityLightsEvent.add(light);
			}
		}


		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush) 
			luaArray.push(new FunkinLua(luaFile));
		#end

		if(!modchartSprites.exists('blammedLightsBlack')) { //Creates blammed light black fade in case you didn't make your own
			blammedLightsBlack = new ModchartSprite(FlxG.width * -0.5, FlxG.height * -0.5);
			blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
			var position:Int = members.indexOf(gfGroup);
			if(members.indexOf(boyfriendGroup) < position) {
				position = members.indexOf(boyfriendGroup);
			} else if(members.indexOf(dadGroup) < position) {
				position = members.indexOf(dadGroup);
			}
			insert(position, blammedLightsBlack);

			blammedLightsBlack.wasAdded = true;
			modchartSprites.set('blammedLightsBlack', blammedLightsBlack);
		}
		if(curStage == 'philly') insert(members.indexOf(blammedLightsBlack) + 1, phillyCityLightsEvent);
		blammedLightsBlack = modchartSprites.get('blammedLightsBlack');
		blammedLightsBlack.alpha = 0.0;

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}
		
		if (isStoryMode == false && SONG.song.toLowerCase() == 'sleepover'){
		switch(charSelection){
		case 0:
		gf = new Character(0, 0, gfVersion);
		case 1:
		gf = new Character(0, 0, 'oooshegone');
		}
		}
		else if (isStoryMode == false && SONG.song.toLowerCase() == 'protocol'){
		switch(charSelection){
		case 0:
		gf = new Character(0, 0, gfVersion);
		case 1:
		gf = new Character(0, 0, 'oooshegone');
		}
		}
		else if (isStoryMode == false && SONG.song.toLowerCase() == 'caution'){
		switch(charSelection){
		case 0:
		gf = new Character(0, 0, gfVersion);
		case 1:
		gf = new Character(0, 0, 'oooshegone');
		}
		}
		else { 
		gf = new Character(0, 0, gfVersion);
		}	
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);
		startCharacterLua(gf.curCharacter);

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
		
		if (isStoryMode == false && SONG.song.toLowerCase() == 'sleepover'){
		switch(charSelection){
		case 0:
		boyfriend = new Boyfriend(0, 0, 'bfwalten');
		case 1:
		boyfriend = new Boyfriend(0, 0, 'picowalten');
		GameOverSubstate.characterName = 'picodead';
		}
		}
		else if (isStoryMode == false && SONG.song.toLowerCase() == 'protocol'){
		switch(charSelection){
		case 0:
		boyfriend = new Boyfriend(0, 0, 'bfpromo');
		case 1:
		boyfriend = new Boyfriend(0, 0, 'picopromo');
		GameOverSubstate.characterName = 'picodead';
		}
		}
		else if (isStoryMode == false && SONG.song.toLowerCase() == 'caution'){
		switch(charSelection){
		case 0:
		boyfriend = new Boyfriend(0, 0, 'bfwaltendark');
		case 1:
		boyfriend = new Boyfriend(0, 0, 'picowaltendark');
		GameOverSubstate.characterName = 'picodead';
		}
		}
		else { 
		boyfriend = new Boyfriend(0, 0, SONG.player1); 
		}	
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		
		
		
		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			gf.visible = false;
		}

		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
			
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				insert(members.indexOf(dadGroup) - 1, evilTrail);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(SUtil.getPath() + file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(SUtil.getPath() + file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;
	
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = SUtil.getPath() + Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = SUtil.getPath() + Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.91;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.08* FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 1, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 85;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 85;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "Botplay", 22);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
	
	var creditTxt = new FlxText(876, 648, 348);
    creditTxt.text = "PORTED BY\nFNF BR";
    creditTxt.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
    creditTxt.scrollFactor.set();
    add(creditTxt);
	
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}
	
                if(ClientPrefs.downScroll) {
			creditTxt.y = 148;
		}
	
		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
	creditTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
	
                #if android
                addAndroidControls();
                #end
	
		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [SUtil.getPath() + Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		
		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
					
				case 'quantum':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('Prologue Cutscene');
					}
					else { 
					startCountdown();
					}
				case 'protocol':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('Week 1 Cutscene 1');
					}
					else { 
					startCountdown();
					}
				case 'sleepover':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('Week 1 Cutscene 2');
					}
					else { 
					startCountdown();
					}
				case 'caution':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('Week 1 Cutscene 3');
					}
					else { 
					startCountdown();
					}
				case 'relocation':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('Week 2 Cutscene 1');
					}
					else { 
					startCountdown();
					}
				case 'starving':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('Week 2 Cutscene 2');
					}
					else { 
					startCountdown();
					}
				case 'mangled':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('Week 2 Cutscene 3');
					}
					else { 
					startCountdown();
					}
				case 'blunder':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('Week 2 Cutscene 4');
					}
					else { 
					startCountdown();
					}
				case 'stranger':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('MH Cutscene 1');
					}
					else { 
					startCountdown();
					}
				case 'boogeyman':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('MH Cutscene 2');
					}
					else { 
					startCountdown();
					}
				case 'lies':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('BG Cutscene 1');
					}
					else { 
					startCountdown();
					}
				case 'ripple':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('BG Cutscene 2');
					}
					else { 
					startCountdown();
					}
				case 'mortality':
					if(!ClientPrefs.getGameplaySetting('cutsceneskip', false)){
					startVideo('BG Cutscene 3');
					}
					else { 
					startCountdown();
					}
					
				default:
					startCountdown();
					
					
			}
			seenCutscene = true;
		} else {
			startCountdown();
		}
		
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');
		CoolUtil.precacheMusic('breakfast');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);
		
		super.create();
		if (curSong.toLowerCase()  == "quantum" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "protocol" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "sleepover" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "caution" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "relocation" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "starving" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "mangled" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "blunder" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "stranger" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "boogeyman" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "lies" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "ripple" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "mortality" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "remember" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "grain" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "roots" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "spin" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "ursidae" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "marketable plushie" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "minutos" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "lucky you" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "repurpose" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "rendezvous" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		
		if (curSong.toLowerCase()  == "sleepover (remix)" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "caution (remix)" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "protocol pico" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "sleepover pico" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (curSong.toLowerCase()  == "caution pico" && ClientPrefs.shaders){
			addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		}
		if (ClientPrefs.squareRatio && isStoryMode == true && seenCutscene == true){
			
		}
		
		Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
			
		switch (SONG.song.toLowerCase()) {
			case 'monochrome-pr':
				healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				scoreTxt.alpha = 0;
				timeBar.alpha = 0;
				timeBarBG.alpha = 0;
				timeTxt.alpha = 0;
				dad.visible = false;

				// jumpscare
				jumpScare = new FlxSprite().loadGraphic(Paths.image('pr/PR', 'shared'));
				jumpScare.setGraphicSize(Std.int(FlxG.width * jumpscareSizeInterval), Std.int(FlxG.height * jumpscareSizeInterval));
				jumpScare.updateHitbox();
				jumpScare.screenCenter();
				add(jumpScare);

				jumpScare.setGraphicSize(Std.int(FlxG.width * jumpscareSizeInterval), Std.int(FlxG.height * jumpscareSizeInterval));
				jumpScare.updateHitbox();
				jumpScare.screenCenter();

				jumpScare.visible = false;
				jumpScare.cameras = [camHUD];
				
			case 'remember':
				//strumLineNotes.visible = false;
				//healthBar.alpha = 0;
				//healthBarBG.alpha = 0;
				//iconP1.alpha = 0;
				//iconP2.alpha = 0;
				//scoreTxt.alpha = 0;
				//timeBar.alpha = 0;
				///timeBarBG.alpha = 0;
				//timeTxt.alpha = 0;
				//dad.visible = false;
				iconP1.changeIcon('BF_PROMO');

				case 'grain':
				//strumLineNotes.visible = false;
				//healthBar.alpha = 0;
				//healthBarBG.alpha = 0;
				//iconP1.alpha = 0;
				//iconP2.alpha = 0;
				//scoreTxt.alpha = 0;
				//timeBar.alpha = 0;
				///timeBarBG.alpha = 0;
				//timeTxt.alpha = 0;
				//dad.visible = false;
				iconP1.changeIcon('BF_PROMO');
				
			case 'rendezvous':		
		
				//strumLineNotes.visible = false;
				healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				scoreTxt.alpha = 0;
				timeBar.alpha = 0;
				timeBarBG.alpha = 0;
				timeTxt.alpha = 0;
				dad.alpha = 0;
				boyfriend.alpha = 0;
				
			case 'quantum':
				//strumLineNotes.visible = false;
				blackBG = new BGSprite('black', 0, 0);
				add(blackBG);
				blackBG.screenCenter(X);
				
			case 'lucky you':
				
				boyfriend.visible = false;
				
				blurscreen = new FlxSprite().loadGraphic(Paths.image('blureffect'));
		
				blurscreen.setGraphicSize(Std.int(FlxG.width * blurSizeInterval), Std.int(FlxG.height * blurSizeInterval));
				blurscreen.updateHitbox();
				//blurscreen.screenCenter();
				//add(blurscreen);

				blurscreen.setGraphicSize(Std.int(FlxG.width * blurSizeInterval), Std.int(FlxG.height * blurSizeInterval));
				blurscreen.updateHitbox();
				//blurscreen.screenCenter();
				
				blurscreen.alpha = 0;
		
				//strumLineNotes.visible = false;
				if (ClientPrefs.squareRatio){
				text1 = new BGSprite('luckyyou/text_1-2', -350, 150);
				}
				else{
				text1 = new BGSprite('luckyyou/text_1', -350, 150);
				}
				if (ClientPrefs.squareRatio){
				text2 = new BGSprite('luckyyou/text_2-2', -350, 150);
				}
				else{
				text2 = new BGSprite('luckyyou/text_2', -350, 150);
				}
				if (ClientPrefs.squareRatio){
				text3 = new BGSprite('luckyyou/text_3-2', -350, 150);
				}
				else{
				text3 = new BGSprite('luckyyou/text_3', -350, 150);
				}
				if (ClientPrefs.squareRatio){
				text4 = new BGSprite('luckyyou/text_4-2', -350, 150);
				}
				else{
				text4 = new BGSprite('luckyyou/text_4', -350, 150);
				}
				text5 = new BGSprite('luckyyou/text_5', -350, 150);
				
				add(text1);
				add(text2);
				add(text3);
				add(text4);
				add(text5);
				
				text1.alpha = 0;
				text2.alpha = 0;
				text3.alpha = 0;
				text4.alpha = 0;
				text5.alpha = 0;
				
				if (timeBar.alpha == 1){
					timeBar.alpha = 0;
				}
				
				if (timeBarBG.alpha == 1){
					timeBarBG.alpha = 0;
				}
				
				if (timeTxt.alpha == 1){
					timeTxt.alpha = 0;
				}
				
				
				healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				scoreTxt.alpha = 0;
				timeBar.alpha = 0;
				timeBarBG.alpha = 0;
				timeTxt.alpha = 0;
				//dad.visible = false;
				
				
		case 'ripple':
				blackBG = new BGSprite('BLACK', -200, -200);
				
				add(blackBG);
				healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				
				//strumLineNotes.visible = false;
					
		case 'marketable plushie':
				bannysadBG = new BGSprite('bannysad', -250, -60);
				//strumLineNotes.visible = false;
				add(bannysadBG);
				bannysadBG.alpha = 0;
				healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				scoreTxt.alpha = 0;
				timeBar.alpha = 0;
				timeBarBG.alpha = 0;
				timeTxt.alpha = 0;
				dad.alpha = 0;
				boyfriend.alpha = 0;
				gf.alpha = 0;
				
		case 'mangled':

				// jumpscare
				rosieScreen = new FlxSprite().loadGraphic(Paths.image('pr/RosieBody', 'shared'));
				rosieScreen.setGraphicSize(Std.int(FlxG.width * rosiescreen1SizeInterval), Std.int(FlxG.height * rosiescreen1SizeInterval));
				rosieScreen.updateHitbox();
				rosieScreen.screenCenter();
				add(rosieScreen);

				rosieScreen.setGraphicSize(Std.int(FlxG.width * rosiescreen1SizeInterval), Std.int(FlxG.height * rosiescreen1SizeInterval));
				rosieScreen.updateHitbox();
				rosieScreen.screenCenter();

				rosieScreen.visible = false;
				rosieScreen.cameras = [camHUD];
				
				case 'blunder':

				// jumpscare
				billyJumpscare = new FlxSprite();
		billyJumpscare.frames = Paths.getSparrowAtlas('billy/BillyJump', 'shared');
		billyJumpscare.animation.addByPrefix('pop', 'BillyPop', 24, false);
		billyJumpscare.animation.addByPrefix('go', 'BillyGoDown', 24, false);
		//billyJumpscare.animation.play('pop');
		billyJumpscare.screenCenter();
		billyJumpscare.y += 300;
		//billyJumpscare.setGraphicSize(FlxG.width, FlxG.height);
		billyJumpscare.updateHitbox();
		add(billyJumpscare);
		
		billyJumpscare.cameras = [camHUD];
		billyJumpscare.visible = false;
		
		billyJumpscare2 = new FlxSprite();
		billyJumpscare2.frames = Paths.getSparrowAtlas('billy/BillyJump2', 'shared');
		billyJumpscare2.animation.addByPrefix('pop', 'BillyPop Down', 24, false);
		billyJumpscare2.animation.addByPrefix('go', 'BillyGoDown Down', 24, false);
		//billyJumpscare2.animation.play('pop');
		billyJumpscare2.screenCenter();
		billyJumpscare2.y += -300;
		//billyJumpscare.setGraphicSize(FlxG.width, FlxG.height);
		billyJumpscare2.updateHitbox();
		add(billyJumpscare2);
				
		billyJumpscare2.cameras = [camHUD];
		billyJumpscare2.visible = false;
		
		billyJumpscare3 = new FlxSprite();
		billyJumpscare3.frames = Paths.getSparrowAtlas('billy/BillyJumpLeft', 'shared');
		billyJumpscare3.animation.addByPrefix('pop', 'BillyPop Left', 24, false);
		billyJumpscare3.animation.addByPrefix('go', 'BillyGoDown Left', 24, false);
		//billyJumpscare3.animation.play('pop');
		billyJumpscare3.screenCenter();
		billyJumpscare3.x += -550;
		
		//billyJumpscare.setGraphicSize(FlxG.width, FlxG.height);
		billyJumpscare3.updateHitbox();
		add(billyJumpscare3);
		
		billyJumpscare3.cameras = [camHUD];
		billyJumpscare3.visible = false;
		
		billyJumpscare4 = new FlxSprite();
		billyJumpscare4.frames = Paths.getSparrowAtlas('billy/BillyJumpRight', 'shared');
		billyJumpscare4.animation.addByPrefix('pop', 'BillyPop Right', 24, false);
		billyJumpscare4.animation.addByPrefix('go', 'BillyGoDown Right', 24, false);
		//billyJumpscare4.animation.play('pop');
		billyJumpscare4.screenCenter();
		billyJumpscare4.x += 550;
		
		//billyJumpscare.setGraphicSize(FlxG.width, FlxG.height);
		billyJumpscare4.updateHitbox();
		add(billyJumpscare4);
		
		billyJumpscare4.cameras = [camHUD];
		billyJumpscare4.visible = false;
		
				blackScreen = new FlxSprite().loadGraphic(Paths.image('black'));
				blackScreen.setGraphicSize(Std.int(FlxG.width * blackscreen1SizeInterval), Std.int(FlxG.height * blackscreen1SizeInterval));
				blackScreen.updateHitbox();
				blackScreen.screenCenter();
				add(blackScreen);

				blackScreen.setGraphicSize(Std.int(FlxG.width * blackscreen1SizeInterval), Std.int(FlxG.height * blackscreen1SizeInterval));
				blackScreen.updateHitbox();
				blackScreen.screenCenter();

				blackScreen.visible = false;
				blackScreen.cameras = [camHUD];
				
				
			case 'mortality':
				
				blackScreen = new FlxSprite().loadGraphic(Paths.image('black'));
				blackScreen.setGraphicSize(Std.int(FlxG.width * blackscreen1SizeInterval), Std.int(FlxG.height * blackscreen1SizeInterval));
				blackScreen.updateHitbox();
				blackScreen.screenCenter();
				add(blackScreen);

				blackScreen.setGraphicSize(Std.int(FlxG.width * blackscreen1SizeInterval), Std.int(FlxG.height * blackscreen1SizeInterval));
				blackScreen.updateHitbox();
				blackScreen.screenCenter();

				blackScreen.visible = false;
				blackScreen.cameras = [camHUD];
				
				}

	}
	
	function doSimpleJump()
		{
			trace ('SIMPLE JUMPSCARE');
	var simplejump:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bon'));
	
		
			simplejump.setGraphicSize(FlxG.width, FlxG.height);
				
				
			simplejump.screenCenter();
		
			simplejump.cameras = [camHUD];

			FlxG.camera.shake(0.0025, 0.50);

			add(simplejump);
			
	var simplejump2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bonremix'));
	
		
			simplejump2.setGraphicSize(FlxG.width, FlxG.height);
				
				
			simplejump2.screenCenter();
		
			simplejump2.cameras = [camHUD];

			add(simplejump2);
			
			simplejump.alpha = 0;
				simplejump2.alpha = 0;
				
					if (SONG.song.toLowerCase() == 'caution'){
				simplejump.alpha = 1;
				simplejump2.alpha = 0;
			}
			
			if (SONG.song.toLowerCase() == 'blunder'){
				simplejump.alpha = 1;
				simplejump2.alpha = 0;
			}
	
			
			if (SONG.song.toLowerCase() == 'caution (remix)'){
				simplejump.alpha = 0;
				simplejump2.alpha = 1;
			}
				
	
			FlxG.sound.play(Paths.sound('Bon'), 1);
	
			new FlxTimer().start(0.2, function(tmr:FlxTimer)
			{
				trace('ended simple jump');
				remove(simplejump);
				remove(simplejump2);
			});
		}
		
		function doPRJump()
		{
			trace ('PR JUMPSCARE');

			var PRjump:FlxSprite = new FlxSprite().loadGraphic(Paths.image('PR'));
		
			PRjump.setGraphicSize(FlxG.width, FlxG.height);
				
				
			PRjump.screenCenter();
		
			PRjump.cameras = [camHUD];

			FlxG.camera.shake(0.0025, 0.50);

				
			add(PRjump);
	
			new FlxTimer().start(0.5, function(tmr:FlxTimer)
			{
				trace('ended pr jump');
				remove(PRjump);
			});
		}
		
		function doBilly()
		{
			trace ('BILLY JUMPSCARE');

			
			billyJumpscare.visible = true;
			billyJumpscare.animation.play('pop');
			
			billyJumpscare.animation.finishCallback = function(pog:String)
			{
				trace('ended billy');
				billyJumpscare.animation.play('go');
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					billyJumpscare.visible = false;
				});
			}
	
			
			if (FlxG.keys.justPressed.SPACE && billyJumpscare.visible != true)
			{
				trace('ended billy');
				billyJumpscare.animation.play('go');
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					billyJumpscare.visible = false;
				});
			}
			
		}
		
		
		
		function doBilly2()
		{
			trace ('BILLY2 JUMPSCARE');
			billyJumpscare2.visible = true;
			billyJumpscare2.animation.play('pop');	
		
			billyJumpscare2.animation.finishCallback = function(pog:String)
			{
				trace('ended billy2');
				billyJumpscare2.animation.play('go');
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					billyJumpscare2.visible = false;
				});
			}
			
				if (FlxG.keys.justPressed.SPACE && billyJumpscare2.visible != true)
			{
				trace('ended billy2');
				billyJumpscare2.animation.play('go');
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					billyJumpscare2.visible = false;
				});
			}
	
		}
		
		function doBilly3()
		{
			trace ('BILLY3 JUMPSCARE');	
			billyJumpscare3.visible = true;
			billyJumpscare3.animation.play('pop');	
		
			billyJumpscare3.animation.finishCallback = function(pog:String)
			{
				trace('ended billy3');
				billyJumpscare3.animation.play('go');
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					billyJumpscare3.visible = false;
				});
			}
			
			if (FlxG.keys.justPressed.SPACE && billyJumpscare3.visible != true)
			{
				trace('ended billy3');
				billyJumpscare3.animation.play('go');
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					billyJumpscare3.visible = false;
				});
			}
	
		}
		
		function doBilly4()
		{
			trace ('BILLY4 JUMPSCARE');
			
			billyJumpscare4.visible = true;
			billyJumpscare4.animation.play('pop');
		
			billyJumpscare4.animation.finishCallback = function(pog:String)
			{
				trace('ended billy4');
				billyJumpscare4.animation.play('go');
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					billyJumpscare4.visible = false;
				});
			}
			
			if (FlxG.keys.justPressed.SPACE && billyJumpscare4.visible != true)
			{
				trace('ended billy4');
				billyJumpscare4.animation.play('go');
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					billyJumpscare4.visible = false;
				});
			}
	
		}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(!gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = SUtil.getPath() + Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}
	
	//SHADER CODE STARTS HERE
	public function addShaderToCamera(cam:String,effect:ShaderEffect){//STOLE FROM ANDROMEDA AND PSYCH ENGINE 0.5.1 WITH SHADERS
      
      
      
        switch(cam.toLowerCase()) {
            case 'camhud' | 'hud':
                    camHUDShaders.push(effect);
                    var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
                    for(i in camHUDShaders){
                      newCamEffects.push(new ShaderFilter(i.shader));
                    }
                    camHUD.setFilters(newCamEffects);
            case 'camother' | 'other':
                    camOtherShaders.push(effect);
                    var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
                    for(i in camOtherShaders){
                      newCamEffects.push(new ShaderFilter(i.shader));
                    }
                    camOther.setFilters(newCamEffects);
            case 'camgame' | 'game':
                    camGameShaders.push(effect);
                    var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
                    for(i in camGameShaders){
                      newCamEffects.push(new ShaderFilter(i.shader));
                    }
                    camGame.setFilters(newCamEffects);
            default:
                if(modchartSprites.exists(cam)) {
                    Reflect.setProperty(modchartSprites.get(cam),"shader",effect.shader);
                } else if(modchartTexts.exists(cam)) {
                    Reflect.setProperty(modchartTexts.get(cam),"shader",effect.shader);
                } else {
                    var OBJ = Reflect.getProperty(PlayState.instance,cam);
                    Reflect.setProperty(OBJ,"shader", effect.shader);
                }
            
            
                
                
        }
      
      
      
      
  }

  public function removeShaderFromCamera(cam:String,effect:ShaderEffect){
      
      
        switch(cam.toLowerCase()) {
            case 'camhud' | 'hud': 
    camHUDShaders.remove(effect);
    var newCamEffects:Array<BitmapFilter>=[];
    for(i in camHUDShaders){
      newCamEffects.push(new ShaderFilter(i.shader));
    }
    camHUD.setFilters(newCamEffects);
            case 'camother' | 'other': 
                    camOtherShaders.remove(effect);
                    var newCamEffects:Array<BitmapFilter>=[];
                    for(i in camOtherShaders){
                      newCamEffects.push(new ShaderFilter(i.shader));
                    }
                    camOther.setFilters(newCamEffects);
            default: 
                camGameShaders.remove(effect);
                var newCamEffects:Array<BitmapFilter>=[];
                for(i in camGameShaders){
                  newCamEffects.push(new ShaderFilter(i.shader));
                }
                camGame.setFilters(newCamEffects);
        }
        
      
  }
    
    
    
  public function clearShaderFromCamera(cam:String){
      
      
        switch(cam.toLowerCase()) {
            case 'camhud' | 'hud': 
                camHUDShaders = [];
                var newCamEffects:Array<BitmapFilter>=[];
                camHUD.setFilters(newCamEffects);
            case 'camother' | 'other': 
                camOtherShaders = [];
                var newCamEffects:Array<BitmapFilter>=[];
                camOther.setFilters(newCamEffects);
            default: 
                camGameShaders = [];
                var newCamEffects:Array<BitmapFilter>=[];
                camGame.setFilters(newCamEffects);
        }
        
      
  }
  //SHADER CODE ENDS HERE
	
	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		#if desktop
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);


			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				startAndEnd();
			}


			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#end
		startAndEnd();
	}

	
	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if (ret != FunkinLua.Function_Stop) {
			var enemyAlpha:Float = 1;
			var playerAlpha:Float = 1;
			if (SONG.song.toLowerCase() == 'rendezvous') {
				enemyAlpha = 0;
				playerAlpha = 0;
			}
			if (SONG.song.toLowerCase() == 'ripple') {
				enemyAlpha = 0;
				playerAlpha = 0;
			}
			if (SONG.song.toLowerCase() == 'quantum') {
				enemyAlpha = 0;
				playerAlpha = 0;
			}
			if (SONG.song.toLowerCase() == 'marketable plushie') {
				enemyAlpha = 0;
				playerAlpha = 0;
			}
			#if android
                        androidControls.visible = true;
                        #end
				
			generateStaticArrows(0, enemyAlpha);
			generateStaticArrows(1, playerAlpha);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (skipCountdown){
				Conductor.songPosition = 0;
				Conductor.songPosition -= Conductor.crochet ;
				swagCounter = 3;
			}
			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (tmr.loopsLeft % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
				{
					gf.dance();
				}
				if(tmr.loopsLeft % 2 == 0) {
					if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
					{
						boyfriend.dance();
					}
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					{
						dad.dance();
					}
				}
				else if(dad.danceIdle && dad.animation.curAnim != null && !dad.stunned && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing"))
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);
	
					bottomBoppers.dance(true);
					santa.dance(true);
				}
				
					if(curStage == 'relocateroom') {
					//if(!ClientPrefs.lowQuality)
					bottomBoppers.dance(true);
					bouncingkidsBG.dance(true);
				}
				
				if(curStage == 'quantum') {
					//if(!ClientPrefs.lowQuality)
					halloweenBG.dance(false);
				}
				
				if(curStage == 'littlebonroom') {
					//if(!ClientPrefs.lowQuality)
					BonSofa.dance(true);
				}
				
				if(curStage == 'littlebonroomremix') {
					//if(!ClientPrefs.lowQuality)
					BonSofa.dance(true);
					DJ.dance(true);
					BillyDance.dance(true);
					BoozooDance.dance(true);
				}
				
				if(curStage == 'toyshop') {
					//if(!ClientPrefs.lowQuality)
					bottomBoppers.dance(true);
					toyshop2BG.dance(true);
				}
				
				if(curStage == 'jollyroom') {
					//if(!ClientPrefs.lowQuality)
					bottomBoppers.dance(true);
				}
				
				
				if(curStage == 'sadroom') {
					//if(!ClientPrefs.lowQuality)
					bottomBoppers.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						if (!skipCountdown){
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						}
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = 1 * note.multAlpha;
					if(ClientPrefs.middleScroll && !note.mustPress) {
						note.alpha *= 0.5;
					}
				});
				
			
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		
		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}
		
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		
		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();
		if (SONG.needsVoices && boyfriend.curCharacter == 'picowalten' || SONG.needsVoices && boyfriend.curCharacter == 'picowaltendark' || SONG.needsVoices && boyfriend.curCharacter == 'picopromo')
			vocals = new FlxSound().loadEmbedded(Paths.voicesPico(PlayState.SONG.song));

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(SUtil.getPath() + file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int, targetAlpha:Float):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0.35;
if (SONG.song.toLowerCase() == 'rendezvous') targetAlpha = 0;
if (SONG.song.toLowerCase() == 'ripple') targetAlpha = 0;
if (SONG.song.toLowerCase() == 'quantum') targetAlpha = 0;
if (SONG.song.toLowerCase() == 'marketable plushie') targetAlpha = 0;
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = false;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = true;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = true;
			
			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}
		
		if (dad.curCharacter == 'bonanimatronicdark' && SONG.song.toLowerCase() == 'caution' && CoolUtil.difficultyString() == 'HARD' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 60 && health > 0.01)  health -= 0.002;
		if (dad.curCharacter == 'bonanimatronicdark' && SONG.song.toLowerCase() == 'caution' && CoolUtil.difficultyString() == 'HARD' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 120 && ClientPrefs.framerate >= 61 && health > 0.01) health -= 0.0005;
		if (dad.curCharacter == 'bonanimatronicdark' && SONG.song.toLowerCase() == 'caution' && CoolUtil.difficultyString() == 'HARD' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 240 && ClientPrefs.framerate >= 121 && health > 0.01) health -= 0.0007;
		
		if (dad.curCharacter == 'bonanimatronicremixdark' && SONG.song.toLowerCase() == 'caution (remix)' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 60 && health > 0.01)  health -= 0.002;
		if (dad.curCharacter == 'bonanimatronicremixdark' && SONG.song.toLowerCase() == 'caution (remix)' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 120 && ClientPrefs.framerate >= 61 && health > 0.01) health -= 0.0005;
		if (dad.curCharacter == 'bonanimatronicremixdark' && SONG.song.toLowerCase() == 'caution (remix)' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 240 && ClientPrefs.framerate >= 121 && health > 0.01) health -= 0.0007;
		
		if (dad.curCharacter == 'bonanimatronicdark' && SONG.song.toLowerCase() == 'caution pico' && CoolUtil.difficultyString() == 'PICO' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 60 && health > 0.01)  health -= 0.002;
		if (dad.curCharacter == 'bonanimatronicdark' && SONG.song.toLowerCase() == 'caution pico' && CoolUtil.difficultyString() == 'PICO' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 120 && ClientPrefs.framerate >= 61 && health > 0.01) health -= 0.0005;
		if (dad.curCharacter == 'bonanimatronicdark' && SONG.song.toLowerCase() == 'caution pico' && CoolUtil.difficultyString() == 'PICO' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 240 && ClientPrefs.framerate >= 121 && health > 0.01) health -= 0.0007;
		
		if (dad.curCharacter == 'eduardo' && SONG.song.toLowerCase() == 'caution' && CoolUtil.difficultyString() == 'HARD' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 60 && health > 0.01)  health -= 0.002;
		if (dad.curCharacter == 'eduardo' && SONG.song.toLowerCase() == 'caution' && CoolUtil.difficultyString() == 'HARD' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 120 && ClientPrefs.framerate >= 61 && health > 0.01) health -= 0.0005;
		if (dad.curCharacter == 'eduardo' && SONG.song.toLowerCase() == 'caution' && CoolUtil.difficultyString() == 'HARD' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 240 && ClientPrefs.framerate >= 121 && health > 0.01) health -= 0.0007;
		
		//if (dad.curCharacter == 'bonanimatronicdark' && SONG.song.toLowerCase() == 'caution (remix)' && (dad.animation.curAnim.name.startsWith('sing'))) health -= 0.0005;
		if (dad.curCharacter == 'briandarkremix' && SONG.song.toLowerCase() == 'caution (remix)' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 60)  health -= 0.002;
		if (dad.curCharacter == 'briandarkremix' && SONG.song.toLowerCase() == 'caution (remix)' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 120 && ClientPrefs.framerate >= 61) health -= 0.0005;
		if (dad.curCharacter == 'briandarkremix' && SONG.song.toLowerCase() == 'caution (remix)' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 240 && ClientPrefs.framerate >= 121) health -= 0.0007;
		
		if (dad.curCharacter == 'pranimatronicdark' && SONG.song.toLowerCase() == 'boogeyman' && CoolUtil.difficultyString() == 'HARD' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 60 && health > 0.01) health -= 0.002;
		if (dad.curCharacter == 'pranimatronicdark' && SONG.song.toLowerCase() == 'boogeyman' && CoolUtil.difficultyString() == 'HARD' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 120 && ClientPrefs.framerate >= 61 && health > 0.01) health -= 0.0005;
		if (dad.curCharacter == 'pranimatronicdark' && SONG.song.toLowerCase() == 'boogeyman' && CoolUtil.difficultyString() == 'HARD' && (dad.animation.curAnim.name.startsWith('sing')) && ClientPrefs.framerate <= 240 && ClientPrefs.framerate >= 121 && health > 0.01) health -= 0.0007;
		
		if (curSong.toLowerCase()  == "lucky you" && health > 1){
			FlxTween.tween(blurscreen, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
		}
		
		if (curSong.toLowerCase()  == "lucky you" && health < 0.76 && health > 0.74){
			//blurscreen.alpha = 0.25;
			FlxTween.tween(blurscreen, {alpha: 0.50}, 0.3, {ease: FlxEase.linear});	
		}
		
		if (curSong.toLowerCase()  == "lucky you" && health < 0.51 && health > 0.49){
			FlxTween.tween(blurscreen, {alpha: 0.75}, 0.3, {ease: FlxEase.linear});	
		}
		
		if (curSong.toLowerCase()  == "lucky you" && health < 0.26 && health > 0.24){
			FlxTween.tween(blurscreen, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
		}
		
	
		
		//if (curSong.toLowerCase()  == "rendezvous" && health < 0.50 && health > 0.48){
		//addShaderToCamera('camGame', new VCRDistortionEffect(0.1, true, true, true));
			//addShaderToCamera('camHUD', new VCRDistortionEffect(0.1, true, true, true));
		//}
		
		//if (curSong.toLowerCase()  == "rendezvous" && health > 0.50){
			//shader.distortionOn.value[0] = 0;
			//shader.scanlinesOn.value[0] = 0;
		//}

		super.update(elapsed);

		if(ratingName == '?') {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
		} else {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
		}

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelMusicFadeTween();
					MusicBeatState.switchState(new GitarooPause());
				}
				else {*/
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}
		
				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		/*var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		*/

		switch(ClientPrefs.iconBounce)
		{
			case 'Old Bounce':
				var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
				iconP1.scale.set(mult, mult);
				iconP1.updateHitbox();

				var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
				iconP2.scale.set(mult, mult);
				iconP2.updateHitbox();

				var iconOffset:Int = 26;

				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

			case 'New Bounce':
				var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

			default:
				var iconOffset:Int = 26;

				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		}

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = 3000;//shit be werid on 4:3
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) //Downscroll
				{
					//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}
				else //Upscroll
				{
					//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if(daNote.copyAlpha)
					daNote.alpha = strumAlpha;
				
				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if(daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if(strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if(PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							} else {
								daNote.y -= 19;
							}
						} 
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}
				
				var center:Float = strumY + Note.swagWidth / 2;
				if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
					(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();

		if (!inCutscene) {
			if(!cpuControlled) {
				keyShit();
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}
		
		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime + 800 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if(daNote.strumTime + 800 >= Conductor.songPosition) {
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		for (i in shaderUpdates){
			i(elapsed);
		}
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}
				
				case 'Jumpscare':
					jumpscare(Std.parseFloat(value1), Std.parseFloat(value2));
					
					case 'Rosie Dead':
					rosiescreen1(Std.parseFloat(value1), Std.parseFloat(value2));
					
					case 'Black Screen':
					blackscreen1(Std.parseFloat(value1), Std.parseFloat(value2));

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 1;
				gfSpeed = value;

			case 'Blammed Lights':
				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				if(lightId > 0 && curLightEvent != lightId) {
					if(lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);

					var color:Int = 0xffffffff;
					switch(lightId) {
						case 1: //Blue
							color = 0xff31a2fd;
						case 2: //Green
							color = 0xff31fd8c;
						case 3: //Pink
							color = 0xfff794f7;
						case 4: //Red
							color = 0xfff96d63;
						case 5: //Orange
							color = 0xfffba633;
					}
					curLightEvent = lightId;

					if(blammedLightsBlack.alpha == 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = FlxTween.color(chars[i], 1, FlxColor.WHITE, color, {onComplete: function(twn:FlxTween) {
								chars[i].colorTween = null;
							}, ease: FlxEase.quadInOut});
						}
					} else {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = null;
						blammedLightsBlack.alpha = 1;

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = null;
						}
						dad.color = color;
						boyfriend.color = color;
						gf.color = color;
					}
					
					if(curStage == 'philly') {
						if(phillyCityLightsEvent != null) {
							phillyCityLightsEvent.forEach(function(spr:BGSprite) {
								spr.visible = false;
							});
							phillyCityLightsEvent.members[lightId - 1].visible = true;
							phillyCityLightsEvent.members[lightId - 1].alpha = 1;
						}
					}
				} else {
					if(blammedLightsBlack.alpha != 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});
					}

					if(curStage == 'philly') {
						phillyCityLights.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});
						phillyCityLightsEvent.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});

						var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
						if(memb != null) {
							memb.visible = true;
							memb.alpha = 1;
							if(phillyCityLightsEventTween != null)
								phillyCityLightsEventTween.cancel();

							phillyCityLightsEventTween = FlxTween.tween(memb, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
								phillyCityLightsEventTween = null;
							}, ease: FlxEase.quadInOut});
						}
					}

					var chars:Array<Character> = [boyfriend, gf, dad];
					for (i in 0...chars.length) {
						if(chars[i].colorTween != null) {
							chars[i].colorTween.cancel();
						}
						chars[i].colorTween = FlxTween.color(chars[i], 1, chars[i].color, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
							chars[i].colorTween = null;
						}, ease: FlxEase.quadInOut});
					}

					curLight = 0;
					curLightEvent = 0;
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;
		
						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf) {
									gf.visible = true;
								}
							} else {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf.curCharacter != value2) {
							if(!gfMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = gf.alpha;
							gf.alpha = 0.00001;
							gf = gfMap.get(value2);
							gf.alpha = lastAlpha;
						}
						setOnLuas('gfName', gf.curCharacter);
				}
				reloadHealthBarColors();
			
			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();
			
			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

		var jumpscareSizeInterval:Float = 1.625;
		

	function jumpscare(chance:Float, duration:Float) {
		// jumpscare
		//if (!ClientPrefs.photosensitive) {
			var outOfTen:Float = Std.random(10);
			if (outOfTen <= ((!Math.isNaN(chance)) ? chance : 4)) {
				jumpScare.visible = true;
				camHUD.shake(0.0125 * (jumpscareSizeInterval / 2), (((!Math.isNaN(duration)) ? duration : 1) * Conductor.stepCrochet) / 1000, 
					function(){
						jumpScare.visible = false;
						jumpscareSizeInterval += 0.125;
						jumpScare.setGraphicSize(Std.int(FlxG.width * jumpscareSizeInterval), Std.int(FlxG.height * jumpscareSizeInterval));
						jumpScare.updateHitbox();
						jumpScare.screenCenter();
					}, true
				);
			}
		
	}
	
	var blurSizeInterval:Float = 1.625;
	
	var blackscreen1SizeInterval:Float = 1.625;

function blackscreen1(chance:Float, duration:Float) {
		// jumpscare
		//if (!ClientPrefs.photosensitive) {
			var outOfTen:Float = Std.random(10);
			if (outOfTen <= ((!Math.isNaN(chance)) ? chance : 4)) {
				blackScreen.visible = true;
				camHUD.shake(0.0125 * (blackscreen1SizeInterval / 2), (((!Math.isNaN(duration)) ? duration : 1) * Conductor.stepCrochet) / 1000, 
					function(){
						blackScreen.visible = false;
						blackscreen1SizeInterval += 0.125;
						blackScreen.setGraphicSize(Std.int(FlxG.width * blackscreen1SizeInterval), Std.int(FlxG.height * blackscreen1SizeInterval));
						blackScreen.updateHitbox();
						blackScreen.screenCenter();
					}, true
				);
			}
		
	}
	
	var rosiescreen1SizeInterval:Float = 1.625;

function rosiescreen1(chance:Float, duration:Float) {
		// jumpscare
		//if (!ClientPrefs.photosensitive) {
			var outOfTen:Float = Std.random(10);
			if (outOfTen <= ((!Math.isNaN(chance)) ? chance : 4)) {
				rosieScreen.visible = true;
				camHUD.shake(0 * (rosiescreen1SizeInterval / 2), (((!Math.isNaN(duration)) ? duration : 1) * Conductor.stepCrochet) / 1000, 
					function(){
						rosieScreen.visible = false;
						rosiescreen1SizeInterval += 0.125;
						rosieScreen.setGraphicSize(Std.int(FlxG.width * rosiescreen1SizeInterval), Std.int(FlxG.height * rosiescreen1SizeInterval));
						rosieScreen.updateHitbox();
						rosieScreen.screenCenter();
					}, true
				);
			}
		
	}
	
	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0];
			camFollow.y += gf.cameraPosition[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}
		
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement();

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		
		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}
			

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('mainMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					///if()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freeplay'));
				changedDifficulty = false;
			
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				score = 50;
				shits++;
			case "bad": // bad
				totalNotesHit += 0.5;
				score = 100;
				bads++;
			case "good": // good
				totalNotesHit += 0.75;
				score = 200;
				goods++;
			case "sick": // sick
				totalNotesHit += 1;
				sicks++;
		}


		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			songHits++;
			totalPlayed++;
			RecalculateRating();

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];


		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];


		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = false;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}
							
						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss) {
					noteMissPress(key);
					callOnLuas('noteMissPress', [key]);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}
	
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			} else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		health -= daNote.missHealth * healthLoss;
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;
		
		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		if(char.hasMissAnimations)
		{
			var daAlt = '';
			if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}
	

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if(ClientPrefs.ghostTapping) return;

			if (combo > 5 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if (!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						doSimpleJump();
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				
					case 'Billy_Note': //Hurt note
						doBilly();
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
						
					case 'Billy_Note2': //Hurt note
						doBilly2();
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
					case 'Billy_NoteLeft': //Hurt note
						doBilly3();
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
					case 'Billy_NoteRight': //Hurt note
						doBilly4();
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';
	
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				//if (note.isSustainNote){ wouldn't this be fun : P. i think it would be swell
					
					//if(note.gfNote) {
					//  var anim = animToPlay +"-hold" + daAlt;
					//	if(gf.animation.getByName(anim) == null)anim = animToPlay + daAlt;
					//	gf.playAnim(anim, true);
					//	gf.holdTimer = 0;
					//} else {
					//  var anim = animToPlay +"-hold" + daAlt;
					//	if(boyfriend.animation.getByName(anim) == null)anim = animToPlay + daAlt;
					//	boyfriend.playAnim(anim, true);
					//	boyfriend.holdTimer = 0;
					//}
				//}else{
					if(note.gfNote) {
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					} else {
						boyfriend.playAnim(animToPlay + daAlt, true);
						boyfriend.holdTimer = 0;
					}
				//}
				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}
	
					if(gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}
		
		if(PlayState.SONG.arrowSkin == 'NOTE_assets') {
				skin = 'noteSplashes';
			}
		if(PlayState.SONG.arrowSkin == 'NOTEBG_assets') {
				skin = 'noteSplashes_BG';
			}
			if(PlayState.SONG.arrowSkin == 'NOTEMH_assets') {
				skin  = 'noteSplashes_MH';
			}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
			gf.specialAnim = true;
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.danced = false; //Sets head to the correct position once the animation ends
		gf.playAnim('hairFall');
		gf.specialAnim = true;
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}
		if(gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}
		
		if (dad.curCharacter == 'briandark' && SONG.song.toLowerCase() == 'caution')
			{
				switch (curStep)
				{
					case 832:
						blackBG = new BGSprite('black', -200, -100);
				add(blackBG);
				}
			}
			
			if (dad.curCharacter == 'briandark' && SONG.song.toLowerCase() == 'caution pico')
			{
				switch (curStep)
				{
					case 832:
						blackBG = new BGSprite('black', -200, -100);
				add(blackBG);
				}
			}
			
			if (dad.curCharacter == 'bonanimdarkalt' && SONG.song.toLowerCase() == 'caution')
			{
				switch (curStep)
				{
						case 884:
						BrianBG = new BGSprite('k9_bg3', -250, -100, ['k9 bg30', 'halloweem bg lightning strike']);
						add(BrianBG);
						remove(blackBG);
				}
			}
			
			if (dad.curCharacter == 'bonanimdarkalt' && SONG.song.toLowerCase() == 'caution pico')
			{
				switch (curStep)
				{
						case 884:
						BrianBG = new BGSprite('k9_bg3', -250, -100, ['k9 bg30', 'halloweem bg lightning strike']);
						add(BrianBG);
						remove(blackBG);
				}
			}
			
			if (dad.curCharacter == 'briandark' && SONG.song.toLowerCase() == 'caution eduardo')
			{
				switch (curStep)
				{
					case 832:
						blackBG = new BGSprite('black', -200, -100);
				add(blackBG);
				}
			}
			
			if (dad.curCharacter == 'eduardo' && SONG.song.toLowerCase() == 'caution eduardo')
			{
				switch (curStep)
				{
						case 872:
						BrianBG = new BGSprite('k9_bg3', -250, -100, ['k9 bg30', 'halloweem bg lightning strike']);
						add(BrianBG);
						remove(blackBG);
				}
			}
			
				if (dad.curCharacter == 'briandarkremix' && SONG.song.toLowerCase() == 'caution (remix)')
			{
				switch (curStep)
				{
					case 832:
						blackBG = new BGSprite('black', -200, -100);
				add(blackBG);
				}
			}
			
			if (dad.curCharacter == 'bonanimremixdarkalt' && SONG.song.toLowerCase() == 'caution (remix)')
			{
				switch (curStep)
				{
						case 884:
						BrianBG = new BGSprite('k9_bg3remix', -250, -100, ['k9 bg3remix0', 'halloweem bg lightning strike']);
						add(BrianBG);
						blackBG.alpha = 0;
				}
			}
			
			if (dad.curCharacter == 'bonanimatronicremixdark' && SONG.song.toLowerCase() == 'caution (remix)')
			{
				switch (curStep)
				{
						case 1776:
						blackBG.alpha = 1;
						BrianBG.alpha = 0;
					case 1792:
						blackBG.alpha = 0;
						BrianBG.alpha = 1;
					case 2192:
						blackBG.alpha = 1;
						BrianBG.alpha = 0;
				}
			}
			
			
						
			if (dad.curCharacter == 'ashleydark' && SONG.song.toLowerCase() == 'blunder')
			{
				switch (curStep)
				{
					case 764:
						billyBG.animation.play('hi');
						
						case 767:
						remove(billyBG);
				}
			}
			
				if (dad.curCharacter == 'billyanimdark' && SONG.song.toLowerCase() == 'blunder')
			{
				switch (curStep)
				{
						
					case 1276:
						
						blackBG = new BGSprite('black', -200, -100);
				add(blackBG);
				boyfriend.alpha = 0;
							gf.alpha = 0;
							dad.alpha = 0;
							healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				iconP2.changeIcon('billy-bon');
				
				case 1280:
				remove(blackBG);
				boyfriend.alpha = 1;
							gf.alpha = 1;
							dad.alpha = 1;
							healthBar.alpha = 1;
				healthBarBG.alpha = 1;
				iconP1.alpha = 1;
				iconP2.alpha = 1;
				
				}
			} 
			
			
				
			
			
			if (dad.curCharacter == 'bon' && SONG.song.toLowerCase() == 'sleepover')
			{
				switch (curStep)
				{
						case 1280:
							boyfriend.alpha = 0;
							gf.alpha = 0;
						jackBG.alpha = 1;
						healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				scoreTxt.alpha = 0;
				timeBar.alpha = 0;
				timeBarBG.alpha = 0;
				timeTxt.alpha = 0;
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						}
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						}
					case 1296:
						boyfriend.alpha = 1;
							gf.alpha = 1;
						jackBG.alpha = 0;
						healthBar.alpha = 1;
				healthBarBG.alpha = 1;
				iconP1.alpha = 1;
				iconP2.alpha = 1;
				scoreTxt.alpha = 1;
				timeBar.alpha = 1;
				timeBarBG.alpha = 1;
				timeTxt.alpha = 1;
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
				}
			}
			
			
			
				if (dad.curCharacter == 'bonremix' && SONG.song.toLowerCase() == 'sleepover (remix)')
			{
				switch (curStep)
				{
					case 1392:
						blackBG = new BGSprite('black', -200, -100);
				add(blackBG);
			case 1395:
				halloweenBG.alpha = 0;
				BonSofa.alpha = 0;
					case 1404:
						FlxG.camera.flash(FlxColor.WHITE, 0.5);
						houseBG.alpha = 1;
						DJ.alpha = 1;
				houseBG.alpha = 1;
				BillyDance.alpha = 1;
				BoozooDance.alpha = 1;
					remove(blackBG);
				case 1664:
						boyfriend.alpha = 0;
						gf.alpha = 0;
						jackBG.alpha = 1;
						healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				scoreTxt.alpha = 0;
				timeBar.alpha = 0;
				timeBarBG.alpha = 0;
				timeTxt.alpha = 0;
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						}
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						}
					case 1680:
						boyfriend.alpha = 1;
							gf.alpha = 1;
						jackBG.alpha = 0;
						healthBar.alpha = 1;
				healthBarBG.alpha = 1;
				iconP1.alpha = 1;
				iconP2.alpha = 1;
				scoreTxt.alpha = 1;
				timeBar.alpha = 1;
				timeBarBG.alpha = 1;
				timeTxt.alpha = 1;
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						
				}
			}
			
			if (dad.curCharacter == 'bannyfront' && SONG.song.toLowerCase() == 'starving')
			{
				switch (curStep)
				{
					case 671:
				FlxTween.tween(whiteBG, {alpha: 0}, 2, {ease: FlxEase.linear});
				
					case 895:
						healthBar.alpha = 0;
						healthBarBG.alpha = 0;
						scoreTxt.alpha = 0;
						iconP1.alpha = 0;
						iconP2.alpha = 0;
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
				}
						timeBar.alpha = 0;
						timeBarBG.alpha = 0;
						timeTxt.alpha = 0;
					
						
				}
				
			} 
			
				if (dad.curCharacter == 'starvingrabbit' && SONG.song.toLowerCase() == 'starving')
			{
				switch (curStep)
				{
					case 960:
						remove(banny1BG);
				bannyroomBG.alpha = 1;
				healthBar.alpha = 1;
						healthBarBG.alpha = 1;
						scoreTxt.alpha = 1;
						iconP1.alpha = 1;
						iconP2.alpha = 1;
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
				}
						timeBar.alpha = 1;
						timeBarBG.alpha = 1;
						timeTxt.alpha = 1;
						
					case 1456:
						
						blackBG = new BGSprite('black', -200, -100);
				add(blackBG);
				boyfriend.alpha = 0;
							gf.alpha = 0;
							dad.alpha = 0;
							healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				}
			} 
			
			if (dad.curCharacter == 'bannycaged' && SONG.song.toLowerCase() == 'starving')
			{
				switch (curStep)
				{
		case 1464:
				remove(blackBG);
				whiteBG.alpha = 1;
				bannyroomBG.alpha = 0;
				boyfriend.alpha = 1;
							gf.alpha = 1;
							dad.alpha = 1;
							healthBar.alpha = 1;
				healthBarBG.alpha = 1;
				iconP1.alpha = 1;
				iconP2.alpha = 1;
				}
			} 
			
			
				if (dad.curCharacter == 'promorocket' && SONG.song.toLowerCase() == 'remember')
			{
				switch (curStep)
				{
					case 1:
				//strumLineNotes.visible = true;
				healthBar.alpha = 1;
				healthBarBG.alpha = 1;
				iconP1.alpha = 1;
				iconP2.alpha = 1;
				scoreTxt.alpha = 1;
				timeBar.alpha = 1;
				timeBarBG.alpha = 1;
				timeTxt.alpha = 1;
				dad.visible = true;
				for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
				}
				}
			} 
			
			if (dad.curCharacter == 'gfwaltenfloat' && SONG.song.toLowerCase() == 'quantum')
			{
				switch (curStep)
				{
						case 1:
							blackBG.alpha = 0;
					//for (i in opponentStrums) {
						//FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
								//}
						//for (i in playerStrums) {
							//FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						//}
				//case 2:
						//strumLineNotes.visible = true;
						
						
						case 4:
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 2, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 2, {ease: FlxEase.linear});
				}
				}
				}
				
			
			
			if (dad.curCharacter == 'shats' && SONG.song.toLowerCase() == 'mangled')
			{
				switch (curStep)
				{
					case 576:
				sha2BG.alpha = 1;
				
				case 623:
				sha2BG.alpha = 0;
				
				case 671:
				sha3BG.alpha = 1;
				
				case 702:
				sha3BG.alpha = 0;
				
					case 800:
						sha1BG.alpha = 1;
						iconP2.changeIcon('shats2');
					case 952:
						iconP2.changeIcon('shats3');
					case 960:
						healthBar.alpha = 0;
						healthBarBG.alpha = 0;
						scoreTxt.alpha = 0;
						iconP1.alpha = 0;
						iconP2.alpha = 0;
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
				}
						timeBar.alpha = 0;
						timeBarBG.alpha = 0;
						timeTxt.alpha = 0;
						blackBG = new BGSprite('black', -200, -100);
						sha1BG.alpha = 0;
				sha2BG.alpha = 0;
				sha3BG.alpha = 0;
				houseBG.alpha = 0;
				halloweenBG.alpha = 0;
				add(blackBG);
				blackBG.alpha = 1;

				}
			}
			if (dad.curCharacter == 'rosemaryts' && SONG.song.toLowerCase() == 'mangled')
			{
				switch (curStep)
				{
					case 992:
						FlxTween.tween(blackBG, {alpha: 0}, 3, {ease: FlxEase.linear});
				
					case 1120:
						remove(blackBG);
				}
			}
			
			if (dad.curCharacter == 'bonts' && SONG.song.toLowerCase() == 'mangled')
			{
				switch (curStep)
				{
				case 1232:
						blackBG = new BGSprite('black', -200, -100);
				add(blackBG);
				remove(houseBG);
				remove(halloweenBG);
			
				}
			}
			
			if (boyfriend.curCharacter == 'bfwaltendark' && SONG.song.toLowerCase() == 'mangled')
			{
				switch (curStep)
				{
								case 1272:
									remove(blackBG);
									healthBar.alpha = 1;
						healthBarBG.alpha = 1;
						scoreTxt.alpha = 1;
						iconP1.alpha = 1;
						iconP2.alpha = 1;
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
				}
						timeBar.alpha = 1;
						timeBarBG.alpha = 1;
						timeTxt.alpha = 1;
				//rosieBodyBG.alpha = 1;
				
			
				//rosieBodyBG.alpha = 0;
				
			
				}
			}
			
			if (gf.curCharacter == 'gfbg' && SONG.song.toLowerCase() == 'mortality')
			{
				switch (curStep)
				{
					case 984:
						bottomBoppers.alpha = 0;
						toyshop4BG.alpha = 1;
					toyshop4BG.animation.play('bye');	
				case 991:
				remove(toyshopBG);
			remove(bottomBoppers);
			toyshop4BG.alpha = 0;
				case 1008:
					for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						}
						healthBar.alpha = 0;
						healthBarBG.alpha = 0;
						scoreTxt.alpha = 0;
						iconP1.alpha = 0;
						iconP2.alpha = 0;
				case 1016:
					toyshop3BG.alpha = 1;
					toyshop3BG.animation.play('intro');	
				}
			}
			
			if (boyfriend.curCharacter == 'demongfbg' && SONG.song.toLowerCase() == 'mortality')
			{
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-bg-gf';
				GameOverSubstate.loopSoundName = 'gameOver-bg';
				GameOverSubstate.endSoundName = 'gameOverEnd-bg';
				GameOverSubstate.characterName = 'gf-bg-dead';
				toyshop3BG.alpha = 0;
				toyshop2BG.alpha = 1;
				for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						healthBar.alpha = 1;
						healthBarBG.alpha = 1;
						scoreTxt.alpha = 1;
						iconP1.alpha = 1;
						iconP2.alpha = 1;
				switch (curStep){
					case 1040:
					for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						remove(toyshopBG);
			remove(bottomBoppers);
			toyshop4BG.alpha = 0;
			toyshop3BG.alpha = 0;
				toyshop2BG.alpha = 1;
						case 1056:
					for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						remove(toyshopBG);
			remove(bottomBoppers);
			toyshop4BG.alpha = 0;
			toyshop3BG.alpha = 0;
				toyshop2BG.alpha = 1;
					case 1344:
				FlxG.sound.play(Paths.sound('nutcracker'), 1);
				}
			}
			
			if (boyfriend.curCharacter == 'bfdisappear' && SONG.song.toLowerCase() == 'remember')
			{
					GameOverSubstate.deathSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.loopSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.endSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.characterName = 'rocket-dead';
			}
		
				
			if (boyfriend.curCharacter == 'bfdisappear' && SONG.song.toLowerCase() == 'grain')
			{
					GameOverSubstate.deathSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.loopSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.endSoundName = 'gameOverloop-completesilence';
				GameOverSubstate.characterName = 'bluescreen';
			}
				
				
			if (boyfriend.curCharacter == 'bfwaltendarkremix' && SONG.song.toLowerCase() == 'caution (remix)')
			{
				GameOverSubstate.characterName = 'bfremixdead';
			}
			
			
			if (boyfriend.curCharacter == 'bfwaltenremix' && SONG.song.toLowerCase() == 'sleepover (remix)')
			{
				GameOverSubstate.characterName = 'bfremixdead';
			}
			
			if (SONG.song.toLowerCase() == 'ripple')
			{
				switch (curStep)
				{
					
				//case 1:
					//for (i in opponentStrums) {
						//FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
							//	}
						//for (i in playerStrums) {
							//FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						//}
				//case 2:
						//strumLineNotes.visible = true;
						
				case 120:
				FlxTween.tween(blackBG, {alpha: 0}, 2, {ease: FlxEase.linear});
				case 122:
								for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
								}
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
						}
						FlxTween.tween(healthBar, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 1}, 1, {ease: FlxEase.linear});
						
				case 784:
					FlxTween.tween(healthBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
				}
				
				case 800:
				FlxTween.tween(redBG, {alpha: 1}, 1, {ease: FlxEase.linear});
				
				case 844:
					FlxTween.tween(healthBar, {alpha: 1}, 0.2, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 1}, 0.2, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 1}, 0.2, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 1}, 0.2, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 1}, 0.2, {ease: FlxEase.linear});
						FlxTween.tween(timeBar, {alpha: 1}, 0.2, {ease: FlxEase.linear});
						FlxTween.tween(timeBarBG, {alpha: 1}, 0.2, {ease: FlxEase.linear});
						FlxTween.tween(timeTxt, {alpha: 1}, 0.2, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.2, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.2, {ease: FlxEase.linear});
				}
						FlxTween.tween(redBG, {alpha: 0}, 1, {ease: FlxEase.linear});
				
				//case 848:
					//redBG.alpha = 0;
						
			
				}
			}
			
			
			if (dad.curCharacter == 'bonplush' && SONG.song.toLowerCase() == 'marketable plushie')
			{
				switch (curStep)
				{
					case 1:
						FlxTween.tween(dad, {alpha: 1}, 3.5, {ease: FlxEase.linear});
					case 32:
						strumLineNotes.visible = true;
					healthBar.alpha = 1;
				healthBarBG.alpha = 1;
				iconP1.alpha = 1;
				iconP2.alpha = 1;
				scoreTxt.alpha = 1;
				timeBar.alpha = 1;
				timeBarBG.alpha = 1;
				timeTxt.alpha = 1;
				blackBG.alpha = 0;
				boyfriend.alpha = 1;
				gf.alpha = 1;
				for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 0.1, {ease: FlxEase.linear});
				}
					case 928:
				FlxTween.tween(healthBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
				}
					case 934:
					banny1BG.alpha = 0;
					banny2BG.alpha = 1;
					case 970:
					banny2BG.alpha = 0;
					banny3BG.alpha = 1;
				case 975:
					FlxTween.tween(bannysadBG, {alpha: 1}, 3, {ease: FlxEase.linear});
			} 
			}
			
			if (dad.curCharacter == 'sadghost' && SONG.song.toLowerCase() == 'lies')
			{
				switch (curStep)
				{
					case 621:
						bottomBoppers.alpha = 0;
						bottomBopperstalk.alpha = 1;
				bottomBopperstalk.animation.play('talk');	
				FlxTween.tween(healthBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
				}
				case 694:
					FlxTween.tween(healthBar, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBar, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBarBG, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeTxt, {alpha: 1}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
				}
				case 704:
					bottomBoppers.alpha = 1;
						bottomBopperstalk.alpha = 0;
				case 960:
				FlxTween.tween(healthBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
				}
				case 982:
				bottomBoppers.alpha = 0;
						bottomBoppersup.alpha = 1;
				case 991:
					FlxTween.tween(healthBar, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBar, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBarBG, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeTxt, {alpha: 1}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
				}
			} 
			}  
				
			
			if (SONG.song.toLowerCase() == 'boogeyman' && ratingPercent >= 0.8){
				switch (curStep)
				{
					case 911:
						remove(gf);
					gf = new Character(1050, 100, 'gfmhdark');
					add(gf);
						remove(gfBG);
						FlxG.camera.flash(FlxColor.WHITE, 4);
					}
					}
					
					if (SONG.song.toLowerCase() == 'minutos'){
				switch (curStep)
				{
					case 1308:
						health = 0;
					}
					}
					
				
					
					//timeBar.cameras = [camHUD];
		//timeBarBG.cameras = [camHUD];
		//timeTxt.cameras = [camHUD];
					
					if (SONG.song.toLowerCase() == 'debugtest'){
						FlxTween.tween(healthBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
						}
					}
					
					if (SONG.song.toLowerCase() == 'rendezvous'){
						switch (curStep)
						{
							//case 1:
					//for (i in opponentStrums) {
						//FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
								//}
						//for (i in playerStrums) {
						//	FlxTween.tween(i, {alpha: 0}, 0.1, {ease: FlxEase.linear});
						//}
				//case 2:
						//strumLineNotes.visible = true;
						case 64:
						FlxTween.tween(dad, {alpha: 1}, 3, {ease: FlxEase.linear});
						FlxTween.tween(boyfriend, {alpha: 1}, 3, {ease: FlxEase.linear});
			
				
						case 112:
						FlxTween.tween(healthBar, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBar, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeBarBG, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(timeTxt, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 1}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 1}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
						}
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
						}
						}
					}
					
					
					
					if (SONG.song.toLowerCase() == 'lucky you'){	healthBar.alpha = 0;
						switch (curStep)
						{
						
						case 112:
						
						for (i in opponentStrums) {
						FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
								}
						case 384:
						FlxTween.tween(flashback1BG, {alpha: 1}, 1, {ease: FlxEase.linear});
						case 416:
						flashback1BG.alpha = 0;
					flashback2BG.alpha = 1;
						case 448:
						flashback2BG.alpha = 0;
					flashback3BG.alpha = 1;
					case 480:
						flashback3BG.alpha = 0;
					flashback4BG.alpha = 1;
					case 512:
						FlxTween.tween(flashback4BG, {alpha: 0}, 1, {ease: FlxEase.linear});
						case 518:
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
						}
						case 520:
						FlxTween.tween(text1, {alpha: 1}, 0.5, {ease: FlxEase.linear});
					case 560:
						text1.alpha = 0;
						text2.alpha = 1;
						
						case 572:
						FlxTween.tween(text2, {alpha: 0}, 0.5, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
						}
						case 1088:
						FlxTween.tween(flashback5BG, {alpha: 1}, 1, {ease: FlxEase.linear});
						case 1120:
						flashback5BG.alpha = 0;
					flashback6BG.alpha = 1;
						case 1152:
						flashback6BG.alpha = 0;
					flashback7BG.alpha = 1;
					case 1184:
						flashback7BG.alpha = 0;
					flashback8BG.alpha = 1;	
					case 1216:
						FlxTween.tween(flashback8BG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
						}
						case 1223:
						FlxTween.tween(text3, {alpha: 1}, 0.5, {ease: FlxEase.linear});
					case 1250:
						text3.alpha = 0;
						text4.alpha = 1;
						case 1268:
						text4.alpha = 0;
						text5.alpha = 1;
						case 1273:
							FlxTween.tween(text5, {alpha: 0}, 0.5, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 1}, 1, {ease: FlxEase.linear});
						}
						case 1280:
						FlxTween.tween(flashback9BG, {alpha: 1}, 1, {ease: FlxEase.linear});
						case 1312:
						flashback9BG.alpha = 0;
					flashback10BG.alpha = 1;
						case 1344:
						flashback10BG.alpha = 0;
					flashback11BG.alpha = 1;
					case 1376:
						flashback11BG.alpha = 0;
					flashback12BG.alpha = 1;	
					case 1408:
						FlxTween.tween(flashback12BG, {alpha: 0}, 1, {ease: FlxEase.linear});
						case 1792:
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
							FlxTween.tween(dad, {alpha: 0}, 3, {ease: FlxEase.linear});
							FlxTween.tween(halloweenBG, {alpha: 0}, 3, {ease: FlxEase.linear});
						}
						}
					}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	
	
	
	
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}
		
		if(ClientPrefs.iconBounce == "New Bounce")
		{
			var funny:Float = (healthBar.percent * 0.01) + 0.01;

			//health icon bounce but epic
			if (curBeat % gfSpeed == 0)
			{
				curBeat % (gfSpeed * 2) == 0 ? {
					iconP1.scale.set(1.1, 0.8);
					iconP2.scale.set(1.1, 1.3);

					FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				} : {
					iconP1.scale.set(1.1, 1.3);
					iconP2.scale.set(1.1, 0.8);

					FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				}

				//FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
				//FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});

				iconP1.updateHitbox();
				iconP2.updateHitbox();
			}
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.scale.set(1.3, 1.3);
		iconP2.scale.set(1.3, 1.3);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
		{
			gf.dance();
		}

		if(curBeat % 2 == 0) {
			if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
			{
				boyfriend.dance();
			}
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			{
				dad.dance();
			}
		} else if(dad.danceIdle && dad.animation.curAnim.name != null && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned) {
			dad.dance();
		}

		switch (curStage)
		{
			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);
				
				case 'relocateroom':
				if (heyTimer <= 0) bottomBoppers.dance(true);
				if (heyTimer <= 0) bouncingkidsBG.dance(true);
				
				case 'quantum':
				if (heyTimer <= 0) halloweenBG.dance(true);
				
				case 'littlebonroom':
				if (heyTimer <= 0) BonSofa.dance(true);
				
				case 'littlebonroomremix':
				if (heyTimer <= 0) BonSofa.dance(true);
				if (heyTimer <= 0) DJ.dance(true);
				if (heyTimer <= 0) BillyDance.dance(true);
				if (heyTimer <= 0) BoozooDance.dance(true);
				
				case 'toyshop':
				if (heyTimer <= 0) bottomBoppers.dance(true);
				if (heyTimer <= 0) toyshop2BG.dance(true);
				
				case 'jollyroom':
				if (heyTimer <= 0) bottomBoppers.dance(true);

				case 'sadroom':
				if (heyTimer <= 0) bottomBoppers.dance(true);
				if (heyTimer <= 0) bottomBoppersup.dance(true);
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:BGSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1, [curLight]);

					phillyCityLights.members[curLight].visible = true;
					phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		lastBeatHit = curBeat;

				setOnLuas('curBeat', curBeat);//DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];
	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length) {
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	public static var othersCodeName:String = 'otherAchievements';
	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String {

		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		var achievementsToCheck:Array<String> = achievesToCheck;
		if (achievementsToCheck == null) {
			achievementsToCheck = [];
			for (i in 0...Achievements.achievementsStuff.length) {
				achievementsToCheck.push(Achievements.achievementsStuff[i][2]);
			}
			achievementsToCheck.push(othersCodeName);
		}

		for (i in 0...achievementsToCheck.length) {
			var achievementName:String = achievementsToCheck[i];
			var unlock:Bool = false;

			if (achievementName == othersCodeName) {
				if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
				{
					var weekName:String = WeekData.getWeekFileName();

					for (json in Achievements.loadedAchievements) {
						if (json.unlocksAfter == weekName && !Achievements.isAchievementUnlocked(json.icon) && !json.customGoal) unlock = true;
						achievementName = json.icon;
					}

					for (k in 0...Achievements.achievementsStuff.length) {
						var unlockPoint:String = Achievements.achievementsStuff[k][3];
						if (unlockPoint != null) {
							if (unlockPoint == weekName && !unlock && !Achievements.isAchievementUnlocked(Achievements.achievementsStuff[k][2])) unlock = true;
							achievementName = Achievements.achievementsStuff[k][2];
						}
					}
				}
			}

			for (json in Achievements.loadedAchievements) { //Requires jsons for call
				var ret:Dynamic = callOnLuas('onCheckForAchievement', [json.icon]); //Set custom goals

				//IDK, like
				// if getProperty('misses') > 10 and leName == 'lmao_skill_issue' then return Function_Continue end

				if (ret == FunkinLua.Function_Continue && !Achievements.isAchievementUnlocked(json.icon) && json.customGoal && !unlock) {
					unlock = true;
					achievementName = json.icon;
				}
			}

			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && !unlock) {
				switch(achievementName)
				{
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing /*&& !ClientPrefs.imagesPersist*/) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}
			}

			if(unlock) {
				Achievements.unlockAchievement(achievementName);
				return achievementName;
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}
