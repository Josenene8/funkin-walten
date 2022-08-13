--hi it's me cherry i made this cuz i was upset that i made an animation for a character that's equivalent to gf's "sad" animation
--and i realized it wasn't playing bc there's no code for the gf character to cry when a combo is broken 
--and i thought "wtf. i'm going to fix this no matter how frustrating the process is." so here's my efforts
--btw remove this text that proves *i* made this and i will come for your kneecaps -cherry

--thank you cherry this issue actually bothered me too lol so i'm glad this lua exists -froakii

local hitInARow = 0

function goodNoteHit(id, direction, noteType, isSustainNote)
    if not isSustainNote then
        hitInARow = getProperty(hitInARow)+ 1
    end
end

function noteMiss(id, direction, noteType, isSustainNote)
    if hitInARow >= 10 then
        triggerEvent('Play Animation', 'sad', 'gf')
        hitInARow = 0
    end
end