package;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import Achievements;

class CharSelectState extends MusicBeatState{
    var charsArray:Array<String> = ['BF_WALTEN', 'Pico_WALTEN'];
    var bfBG:FlxSprite;
	var picoBG:FlxSprite;
	var blackBG:FlxSprite;
    var bf:FlxSprite;
    var pico:FlxSprite;
	var bfText:FlxSprite;
    var picoText:FlxSprite;
    var selectedText:FlxText;
    var charSelect:FlxSprite;
	var AnnouncerDetermine:FlxSound;
	var AnnouncerNumber:Int = 0;
	var selectedSomethin:Bool = false;
    public static var curSelected:Int = 0;
    override function create(){
        FlxG.sound.playMusic(Paths.music('CharSelect'));
		AnnouncerNumber = FlxG.random.int(1, 6);
		AnnouncerDetermine = FlxG.sound.play(Paths.sound('announcerchoose-' + AnnouncerNumber));
        bfBG = new FlxSprite().loadGraphic(Paths.image('menuBF'));
        //bfBG.color = FlxColor.BLUE;
        bfBG.screenCenter();
        add(bfBG);
		picoBG = new FlxSprite().loadGraphic(Paths.image('menuPico'));
        //bfBG.color = FlxColor.BLUE;
        picoBG.screenCenter();
        add(picoBG);
		blackBG = new FlxSprite().loadGraphic(Paths.image('charselect/blackgradient'));
        //bfBG.color = FlxColor.BLUE;
        blackBG.screenCenter();
        add(blackBG);
        bf = new FlxSprite(-100, 0).loadGraphic(Paths.image('charselect/BF_Char'));
        bf.frames = Paths.getSparrowAtlas('charselect/BF_Char');
        bf.animation.addByPrefix('idle', 'BF idle dance', 24, true);
        bf.animation.play('idle');
        add(bf);
		
        pico = new FlxSprite(-250, -50).loadGraphic(Paths.image('charselect/PICO_Char'));
        pico.frames = Paths.getSparrowAtlas('charselect/PICO_Char');
        pico.animation.addByPrefix('idle', 'PICO Idle dance', 24, true);
        pico.animation.play('idle');
        add(pico);
		
		bfText = new FlxSprite().loadGraphic(Paths.image('charselect/BFText'));
        //bfBG.color = FlxColor.BLUE;
        bfText.screenCenter();
        add(bfText);
		picoText = new FlxSprite().loadGraphic(Paths.image('charselect/PicoText'));
        //bfBG.color = FlxColor.BLUE;
        picoText.screenCenter();
        add(picoText);
		FlxTween.tween(bfText, {y: bfBG.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});
		FlxTween.tween(picoText, {y: picoBG.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});
		FlxTween.tween(bf, {y: bfBG.y + 50}, 2, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.5});
		FlxTween.tween(pico, {y: picoBG.y + 50}, 2, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.5});
		
		
		selectedText = new FlxText(0, 10, charsArray[0], 24);
		selectedText.alpha = 0.5;
		selectedText.x = (FlxG.width) - (selectedText.width) - 25;
        //add(selectedText);
        charSelect = new Alphabet(0, 50, "Choose Your Character", true, false);
        charSelect.offset.x -= 150;
        add(charSelect);
        changeSelection();
        super.create();
    }

    function changeSelection(change:Int = 0){
        curSelected += change;

        if (curSelected < 0)
			curSelected = charsArray.length - 1;
		if (curSelected >= charsArray.length)
			curSelected = 0;

        //selectedText.text = charsArray[curSelected];

        switch(curSelected){
        case 0:
		//pico.x = -350;
        bf.visible = true;
		//FlxTween.tween(bf, { x: -100, y: 0 }, 0.2);
        pico.visible = false;
        bfBG.visible = true;
		bfText.visible = true;
		picoBG.visible = false;
		picoText.visible = false;
	case 1:
		//bf.x = -200;
        bf.visible = false;
        pico.visible = true;
		//FlxTween.tween(pico, { x: -250, y: 0 }, 0.2);
		bfBG.visible = false;
		bfText.visible = false;
		picoBG.visible = true;
		picoText.visible = true;
        }
    }

    override function update(elapsed:Float){
		if (!selectedSomethin)
		{
			
			if (controls.UI_LEFT_P){
        changeSelection(-1);
        FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (controls.UI_RIGHT_P){
        changeSelection(1);
        FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			
        if (controls.BACK){
			FlxG.sound.music.stop();
        FlxG.sound.play(Paths.sound('cancelMenu'));
        MusicBeatState.switchState(new FreeplayState());
		FlxG.sound.playMusic(Paths.music('mainMenu'), 0);
        }

			if (controls.ACCEPT){
			
        FlxG.sound.playMusic(Paths.music('CharSelect-Confirm'));
		
        switch(curSelected){
        case 1:
			FlxG.sound.play(Paths.sound('announcerpico-' + AnnouncerNumber));
        //pico.animation.play('singDOWN');
		FlxTween.tween(picoBG, { x: 0, y: -20 }, 0.3);
		selectedSomethin = true;
		FlxTween.tween(picoBG, { x: 0, y: -40 }, 7);
	case 0:
		FlxG.sound.play(Paths.sound('announcerbf-' + AnnouncerNumber));
        //bf.animation.play('singUP');
		FlxTween.tween(bfBG, { x: 0, y: -20 }, 0.3);
		selectedSomethin = true;
		FlxTween.tween(bfBG, { x: 0, y: -40 }, 7);
        }
		
		FlxG.camera.flash(FlxColor.WHITE, 0.5);
        new FlxTimer().start(5, function(tmr:FlxTimer)
            {
        MusicBeatState.switchState(new PlayState());
            });
        }
        super.update(elapsed);
    }
}
}
