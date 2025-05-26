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
uiManager.setAudioUI();
uiManager.setMidiInUI(nodeManager.midiInDevices);
uiManager.setMidiOutUI(nodeManager.midiOutDevices);
uiManager.setOscUI();
uiManager.setSequencerUI();
uiManager.setEffectsUI();
uiManager.setUtilsUI();
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

// Add nodes to node manager
nodeManager.addNode(audioOut);
nodeManager.addNode(audioIn);

// Load autosave on startup
nodeManager.loadSave("autosave.json");


// Main loop
while (true) {
    GG.nextFrame() => now;

    // UI
    if (UI.begin("SMUG")) {
        // show a UI display of the current scenegraph
        UI.scenegraph(GG.scene());
    }
    UI.end();
}
