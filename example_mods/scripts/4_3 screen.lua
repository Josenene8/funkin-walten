function onCreate()
if getPropertyFromClass('ClientPrefs', 'squareRatio') == true then
function onCreatePost()
function onUpdate()

makeLuaSprite('borderLeft', 'border', 0, 0); makeLuaSprite('borderRight', 'border', 1120, 0)
 addLuaSprite('borderLeft', false); addLuaSprite('borderRight', false)
 setProperty('borderLeft.antialiasing', false); setProperty('borderRight.antialiasing', false)
 setObjectCamera('borderLeft', 'camOther'); setObjectCamera('borderRight', 'camOther')

end

function onCountdownStarted()
 
 for i = 0, 3 do
  if not middlescroll then
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') + 90)
  end
 end
 
 for i = 4, 7 do
  if not middlescroll then
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') - 70)
  else
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') + 5)
  end
 end

 for i = 2, 3 do
  if middlescroll then
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') - 90)
  end
 end

 for i = 0, 1 do
  if middlescroll then
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') + 100)
  end
 end

end

for i = 0, 3 do
  if not middlescroll then
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') + 90)
  end
 end
 
 for i = 4, 7 do
  if not middlescroll then
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') - 70)
  else
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') + 5)
  end
 end

 for i = 2, 3 do
  if middlescroll then
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') - 90)
  end
 end

 for i = 0, 1 do
  if middlescroll then
   setPropertyFromGroup('strumLineNotes', i, 'x', getPropertyFromGroup('strumLineNotes', i, 'x') + 100)
  end
 end


end
end
end


--script by KaoyDumb