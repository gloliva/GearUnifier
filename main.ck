/*
    How to run: chuck --caution-to-the-wind --dac:2 --out:16 main.ck
*/

// Imports
@import "nodes/audio.ck"
@import "nodes/manager.ck"
@import "nodes/midi.ck"


// Camera / Background
8. => GG.scene().camera().posZ;
GG.scene().camera().orthographic();
Color.WHITE => GG.scene().backgroundColor;
GWindow.fullscreen();


// Audio
AudioOutNode audioOut(16);
audioOut --> GG.scene();
3. => audioOut.posX;
2. => audioOut.posY;

AudioInNode audioIn(12);
audioIn --> GG.scene();
-3. => audioIn.posX;
2. => audioIn.posY;


// Midi 1
MidiInNode midiIn1(0, 1, 3);
midiIn1 --> GG.scene();
2. => midiIn1.posY;

midiIn1.outputDataTypeIdx(MidiDataType.PITCH, 0, 0);
midiIn1.outputDataTypeIdx(MidiDataType.GATE, 0, 1);
midiIn1.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0, 2);

spork ~ midiIn1.run();


// Midi 2
MidiInNode midiIn2(0, 2, 3);
midiIn2 --> GG.scene();
1. => midiIn2.posY;

midiIn2.outputDataTypeIdx(MidiDataType.PITCH, 0, 0);
midiIn2.outputDataTypeIdx(MidiDataType.GATE, 0, 1);
midiIn2.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0, 2);

spork ~ midiIn2.run();


// Midi 3
MidiInNode midiIn3(0, 3, 3);
midiIn3 --> GG.scene();
0. => midiIn3.posY;

midiIn3.outputDataTypeIdx(MidiDataType.PITCH, 0, 0);
midiIn3.outputDataTypeIdx(MidiDataType.GATE, 0, 1);
midiIn3.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0, 2);

spork ~ midiIn3.run();


// Midi 4
MidiInNode midiIn4(0, 4, 3);
midiIn4 --> GG.scene();
-1. => midiIn4.posY;

midiIn4.outputDataTypeIdx(MidiDataType.PITCH, 0, 0);
midiIn4.outputDataTypeIdx(MidiDataType.GATE, 0, 1);
midiIn4.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0, 2);

spork ~ midiIn4.run();


// Node manager
NodeManager nodeManager;
nodeManager.addNode(audioOut);
nodeManager.addNode(audioIn);
nodeManager.addNode(midiIn1);
nodeManager.addNode(midiIn2);
nodeManager.addNode(midiIn3);
nodeManager.addNode(midiIn4);

spork ~ nodeManager.run();


while (true) {
    GG.nextFrame() => now;

    // UI
    if (UI.begin("Nodes Test")) {
        // show a UI display of the current scenegraph
        UI.scenegraph(GG.scene());
    }
    UI.end();
}
