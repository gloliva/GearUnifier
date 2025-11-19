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
MoveCameraEvent moveCameraEvent;
SaveLoadEvent saveLoadEvent;

// Node Manager
NodeManager nodeManager(moveCameraEvent, saveLoadEvent);
nodeManager.findMidiDevices();
spork ~ nodeManager.run();
spork ~ nodeManager.addNodeHandler(addNodeEvent);
spork ~ nodeManager.saveHandler();

// UI
UIManager uiManager(addNodeEvent, moveCameraEvent, saveLoadEvent);
uiManager.setAudioUI();
uiManager.setMidiInUI(nodeManager.midiInDevices);
uiManager.setMidiOutUI(nodeManager.midiOutDevices);
uiManager.setOscUI();
uiManager.setSequencerUI();
uiManager.setEffectsUI();
uiManager.setModifiersUI();
uiManager.setSaveUI();
spork ~ uiManager.resize();
spork ~ uiManager.translate();
spork ~ uiManager.run();


// Main loop
while (true) {
    GG.nextFrame() => now;

    // UI
    // if (UI.begin("GUMS")) {
    //     // show a UI display of the current scenegraph
    //     UI.scenegraph(GG.scene());
    // }
    // UI.end();
}
