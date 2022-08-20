package;
import flixel.*;
class ForOnlinePlayers extends MusicBeatState
{

	public function new() 
	{
		super();
	}
	
	override function create() 
	{
		super.create();
		
		var screen:FlxSprite = new FlxSprite().loadGraphic(Paths.image("html"));
		
		add(screen);
		
		#if android
                addVirtualPad(NONE, A);
                #end
		
	}
	
	
	override function update(elapsed:Float) 
	{
		super.update(elapsed);
		
		if (controls.ACCEPT){
			CoolUtil.browserLoad('gamebanana.com/mods/324059');
			FlxG.switchState(new MainMenuState());
		}
		
		
		
	}
	
}
