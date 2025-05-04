/*
    How to run: chuck --caution-to-the-wind --dac:5 --out:16 --adc:5 --in:12 main.ck
*/

// Imports
@import "nodes/audio.ck"
@import "nodes/manager.ck"
@import "nodes/midi.ck"
@import "ui/manager.ck"
@import "events.ck"
@import "utils.ck"


// Camera / Background
8. => GG.scene().camera().posZ;
GG.scene().camera().orthographic();
Color.WHITE => GG.scene().backgroundColor;
// GWindow.fullscreen();

// Events
AddNodeEvent addNodeEvent;

// Node Manager
NodeManager nodeManager;
nodeManager.findMidiDevices();
spork ~ nodeManager.run();
spork ~ nodeManager.addNodeHandler(addNodeEvent);


// UI
UIManager uiManager(addNodeEvent);
uiManager.setMidiInUI(nodeManager.midiInDevices);
spork ~ uiManager.resize();
spork ~ uiManager.run();


// Audio
AudioOutNode audioOut(dac.channels());
audioOut --> GG.scene();
3. => audioOut.posX;
2. => audioOut.posY;

AudioInNode audioIn(adc.channels());
audioIn --> GG.scene();
-3. => audioIn.posX;
2. => audioIn.posY;


// TODO: MidiDevice, remove when done testing
2 => int midiDeviceID;


// Midi 1
MidiInNode midiIn1(midiDeviceID, 1, 3);
2.5 => midiIn1.posY;

midiIn1.outputDataTypeIdx(MidiDataType.PITCH, 0, 0);
midiIn1.outputDataTypeIdx(MidiDataType.GATE, 0, 1);
midiIn1.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0, 2);

spork ~ midiIn1.run();


// Midi 2
MidiInNode midiIn2(midiDeviceID, 2, 3);
1. => midiIn2.posY;

midiIn2.outputDataTypeIdx(MidiDataType.PITCH, 0, 0);
midiIn2.outputDataTypeIdx(MidiDataType.GATE, 0, 1);
midiIn2.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0, 2);

spork ~ midiIn2.run();


// Midi 3
MidiInNode midiIn3(midiDeviceID, 3, 3);
-1. => midiIn3.posY;

midiIn3.outputDataTypeIdx(MidiDataType.PITCH, 0, 0);
midiIn3.outputDataTypeIdx(MidiDataType.GATE, 0, 1);
midiIn3.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0, 2);

spork ~ midiIn3.run();


// Midi 4
MidiInNode midiIn4(midiDeviceID, 4, 3);
-2.5 => midiIn4.posY;

// midiIn4.outputDataTypeIdx(MidiDataType.PITCH, 0, 0);
// midiIn4.outputDataTypeIdx(MidiDataType.GATE, 0, 1);
// midiIn4.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0, 2);

spork ~ midiIn4.run();


// Add nodes to node manager
nodeManager.addNode(audioOut);
nodeManager.addNode(audioIn);
nodeManager.addNode(midiIn1);
nodeManager.addNode(midiIn2);
nodeManager.addNode(midiIn3);
nodeManager.addNode(midiIn4);


while (true) {
    GG.nextFrame() => now;

    // UI
    if (UI.begin("Nodes Test")) {
        // show a UI display of the current scenegraph
        UI.scenegraph(GG.scene());
    }
    UI.end();
}
