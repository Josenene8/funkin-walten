local Nps = 0;
local NoteHit = false;

function onStepHit()
    if NoteHit == true then
        Nps = Nps - 2 * 4 -- math is funny
    end
end

function onCreate() -- dub ui code wooooooo borrowed code as well lol
	makeLuaSprite('bartop','',0,0);
	makeGraphic('bartop',1280,75,'000000');
	addLuaSprite('bartop',false);
	makeLuaSprite('barbot','',0,650);
	makeGraphic('barbot',1280,100,'000000');
	addLuaSprite('barbot',false);
	setScrollFactor('bartop',0,0);
	setScrollFactor('barbot',0,0);
	setObjectCamera('bartop','hud');
	setObjectCamera('barbot','hud');
end

function onCreatePost()
if getPropertyFromClass('ClientPrefs', 'squareRatio') == true then

    makeLuaText('misses','',0,180,685)
    setTextSize('misses', 25)
    addLuaText('misses')

    makeLuaText('score','',0,180,655)
    setTextSize('score', 25)
    addLuaText('score')
	
	 makeLuaText('accuracy','',0,860,655)
    setTextSize('accuracy', 25)
    addLuaText('accuracy')
	
	 makeLuaText('accuracyname','',0,860,685)
    setTextSize('accuracyname', 25)
    addLuaText('accuracyname')
end
if getPropertyFromClass('ClientPrefs', 'squareRatio') == false then

    makeLuaText('misses','',0,20,685)
    setTextSize('misses', 27)
    addLuaText('misses')

    makeLuaText('score','',0,20,655)
    setTextSize('score', 27)
    addLuaText('score')
	
	 makeLuaText('accuracy','',0,1000,655)
    setTextSize('accuracy', 27)
    addLuaText('accuracy')
	
	 makeLuaText('accuracyname','',0,1000,685)
    setTextSize('accuracyname', 27)
    addLuaText('accuracyname')
end

 setProperty('scoreTxt.visible', false);
 setProperty('timeBar.visible', true);
 setProperty('timeBarBG.visible', true);
 setProperty('timeTxt.visible', true);
end



 function onUpdate()
 if hits < 1 and misses < 1 then
 setTextString('nps','NPS: 0')
else
 setTextString('nps','NPS: '..Nps)
end

  if Nps < 0 then
        Nps = 0
        NoteHit = false;
    end
	
    setTextString('misses','Combo Breaks: '..getProperty('songMisses'))
    setTextString('score','Score: '..getProperty('songScore'))
	setTextString('accuracy','Accuracy: '..round((getProperty('ratingPercent') * 100), 2)..'%')
	setTextString('accuracyname',''..getProperty('ratingName'))
end

function round(num, numDecimalPlaces)

   local mult = 10^(numDecimalPlaces or 0)

   return math.floor(num * mult + 0.5) / mult

end