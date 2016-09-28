git archive --format zip --output ../basic.zip master:basic/
git archive --format zip --output ../sound.zip master:sound/
git archive --format zip --output ../samples.zip master:samples/
git archive --format zip --output ../midi.zip master:midi/
git archive --format zip --output ../scripting.zip master:scripting/
git archive --format zip --output ../taller.zip master:taller/
7z.exe x -y ../basic.zip -o../datam/basic
7z.exe x -y ../sound.zip -o../datam/sound
7z.exe x -y ../samples.zip -o../datam/samples
7z.exe x -y ../midi.zip -o../datam/midi
7z.exe x -y ../taller.zip -o../datam/taller
7z.exe x -y ../scripting.zip -o../datam/scripting
exit