@import {"../../events.ck", "../../utils.ck"}
@import {"../../sequencer/composer.ck", "../../sequencer/instrument.ck"}
@import {"../tuning.ck", "../../tuning/base.ck"}
@import "../../ui/composeBox.ck"
@import "../base.ck"
@import "player.ck"
@import "HashMap"
@import "smuck"


public class ComposerInputType {
    new Enum(0, "Player") @=> static Enum PLAYER;
    new Enum(1, "Scene Num") @=> static Enum SCENE_NUM;
    new Enum(2, "Set Scene") @=> static Enum SET_SCENE;
    new Enum(3, "Queue Scene") @=> static Enum QUEUE_SCENE;
    new Enum(4, "Tuning") @=> static Enum TUNING;

    [
        ComposerInputType.PLAYER,
        ComposerInputType.SCENE_NUM,
        ComposerInputType.SET_SCENE,
        ComposerInputType.QUEUE_SCENE,
        ComposerInputType.TUNING,
    ] @=> static Enum allTypes[];
}


public class ComposerOutputType {
    new Enum(0, "Pitch") @=> static Enum PITCH;
    new Enum(1, "Gate") @=> static Enum GATE;
    new Enum(2, "Envelope") @=> static Enum ENVELOPE;

    [
        ComposerOutputType.PITCH,
        ComposerOutputType.GATE,
        ComposerOutputType.ENVELOPE,
    ] @=> static Enum allTypes[];
}


public class ComposerNode extends Node {
    ComposeBox composeBoxes[0];

    // Scenes
    -1 => int activeScene;
    -1 => int queuedScene;
    -1 => int sceneNumInput;
    0 => int setSceneTrigger;
    0 => int queueSceneTrigger;

    // smuck score parameters
    ezPart part;
    ComposerInstrument @ instrument;
    ScorePlayerNode @ scorePlayer;


    // Events
    ComposeBoxUpdateEvent updateSceneEvent;

    // Outs
    UGen outs[];

    fun @construct() {
        ComposerNode(1, 4.);
    }

    fun @construct(int numStartButtons) {
        ComposerNode(numStartButtons, 4.);
    }

    fun @construct(int numStartButtons, float xScale) {
        // Set default tuning
        EDO defaultTuning(12, -48);

        // Set instrument
        new ComposerInstrument(defaultTuning) @=> this.instrument;

        // Set outs
        [
            this.instrument.pitch,
            this.instrument.gate,
            this.instrument.env,
        ] @=> this.outs;

        // Set node ID and name
        "Composer Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Composer", xScale) @=> this.nodeNameBox;

        // Create inputs box
        ComposerInputType.allTypes @=> this.inputTypes;
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(1, this.inputTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        this.nodeInputsBox.setInput(ComposerInputType.PLAYER, 0);

        // Create outputs box
        ComposerOutputType.allTypes @=> this.outputTypes;
        new IOModifierBox(xScale) @=> this.nodeOutputsModifierBox;
        new IOBox(2, this.outputTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.setOutput(ComposerOutputType.PITCH, 0, this.instrument.pitch);
        this.nodeOutputsBox.setOutput(ComposerOutputType.ENVELOPE, 1, this.instrument.env);

        // Create button box
        new IOModifierBox(xScale) @=> this.nodeButtonModifierBox;
        new ButtonBox(numStartButtons, xScale) @=> this.nodeButtonBox;

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Add compose boxes
        for (int idx; idx < numStartButtons; idx++) {
            ComposeBox composeBox("Scene " + (idx + 1), this.updateSceneEvent, 18, 13);
            composeBox.setID(this.nodeID + " " + composeBox.headerName);
            this.composeBoxes << composeBox;
        }

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeInputsModifierBox --> this;
        this.nodeInputsBox --> this;
        this.nodeOutputsModifierBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeButtonModifierBox --> this;
        this.nodeButtonBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();

        // Shreds
        spork ~ this.processComposeBoxUpdates() @=> Shred @ processComposeBoxShreds;
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        spork ~ this.processSceneChanges() @=> Shred @ processSceneChangesShred;
        this.addShreds([this.instrument.envUpdateShred, processComposeBoxShreds, processInputsShred, processSceneChangesShred]);
    }

    fun void updateMeasures(int sceneId) {
        this.updateMeasures(sceneId, 0);
    }

    fun void updateMeasures(int sceneId, int updateActiveScene) {
        <<< "Updating scene:", sceneId >>>;
        this.composeBoxes[sceneId].measures @=> ezMeasure measures[];

        // Check that there are parsed measures
        if (measures == null) {
            <<< "IDK what to do here" >>>;  // TODO: some kind of error handling
            return;
        }

        if (updateActiveScene) sceneId => this.activeScene;
        this.part.measures(measures);
        if (this.scorePlayer != null) {
            this.scorePlayer.setPart(this.nodeID, this.part, this.instrument);
        }
    }

    fun void setComposeBoxFromFile(int boxIdx, string filePath) {
        if (boxIdx < 0 || boxIdx > this.composeBoxes.size()) {
            <<< "ERROR: Trying to set a ComposeBox with idx", boxIdx >>>;
            return;
        }

        this.composeBoxes[boxIdx].openComposeTextFile(filePath);
    }

    fun void setActiveScene(int sceneId) {
        if (sceneId < 0 || sceneId > this.composeBoxes.size()) {
            <<< "ERROR: Trying to set the active scene to:", sceneId, ". Number of scenes:", this.composeBoxes.size() >>>;
            return;
        }

        this.updateMeasures(sceneId, 1);
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "Composer Connect: No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == ComposerInputType.PLAYER.id) {
            if (Type.of(outputNode).name() == ScorePlayerNode.typeOf().name()) {
                <<< "Connecting a ScorePlayer Node" >>>;
                (outputNode)$ScorePlayerNode @=> this.scorePlayer;
                if (this.instrument != null) {
                    this.instrument.setScorePlayer(this.scorePlayer.scorePlayer);
                }

                if (this.activeScene != -1) {
                    this.scorePlayer.setPart(this.nodeID, this.part, this.instrument);
                }
            }
        } else if (dataType == ComposerInputType.TUNING.id) {
            if (Type.of(outputNode).name() == ScaleTuningNode.typeOf().name()) {
                <<< "Connecting a Tuning File Node" >>>;
                this.instrument.setTuning((outputNode$ScaleTuningNode).tuning);
            } else if (Type.of(outputNode).name() == EDOTuningNode.typeOf().name()) {
                <<< "Connecting an EDO Tuning Node" >>>;
                this.instrument.setTuning((outputNode$EDOTuningNode).tuning);
            }
        }
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "Composer Disconnect: No data type mapping for jack", inputJackIdx, "how did this happen...?" >>>;
            return;
        }

        // Disconnect a ScorePlayerNode
        if (dataType == ComposerInputType.PLAYER.id) {
            if (this.scorePlayer != null) {
                // If a current score is being played, stop the score
                if (this.scorePlayer.isPlaying()) this.scorePlayer.stop();

                // Disconnect
                null => this.scorePlayer;
            }
        // Disconnect a ScalaTuningNode or EDOTuningNode
        } else if (dataType == ComposerInputType.TUNING.id) {
            // Reset to default 12-TET tuning
            this.instrument.setTuning(new EDO(12, -48));
        // Otherwise remove UGen from jack
        } else {
            this.nodeInputsBox.removeJackUGen(inputJackIdx);
        }
    }

    fun void addButton() {
        this.nodeButtonBox.addButton();
        ComposeBox composeBox("Scene " + (this.composeBoxes.size() + 1), this.updateSceneEvent, 18, 13);
        composeBox.setID(this.nodeID + " " + composeBox.headerName);
        this.composeBoxes << composeBox;
    }

    fun void removeButton() {
        this.nodeButtonBox.removeButton();
        this.composeBoxes.popBack();
    }

    fun void handleButtonPress(int buttonIdx) {
        this.composeBoxes[buttonIdx] @=> ComposeBox currComposeBox;

        if (!currComposeBox.active) {
            1 => currComposeBox.active;
        } else {
            0 => currComposeBox.active;
        }
    }

    fun void processComposeBoxUpdates() {
        while (this.nodeActive) {
            this.updateSceneEvent => now;

            this.updateSceneEvent.sceneId => int sceneId;
            if (sceneId != this.activeScene) continue;
            if (!this.composeBoxes[sceneId].good()) continue;

            this.updateMeasures(sceneId);
        }
    }

    fun void processInputs() {
        while (this.nodeActive) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                // Check if this input jack has an associated data type
                this.nodeInputsBox.getDataTypeMapping(idx) => int dataType;
                if (dataType == -1) continue;

                // Get UGen connected to this input jack
                this.nodeInputsBox.getJackUGen(idx) @=> UGen ugen;
                if (ugen == null) continue;

                // Input value from ugen
                this.getValueFromUGen(ugen) => float value;

                // Change scenes by input values
                if (dataType == ComposerInputType.SCENE_NUM.id) {
                    value$int => int sceneNum;
                    if (sceneNum < 0 || sceneNum >= this.composeBoxes.size()) {
                        <<< "ERROR: Trying to set scene #", sceneNum, "for number of scenes:", this.composeBoxes.size() >>>;
                        continue;
                    }

                    if (sceneNum != this.sceneNumInput) sceneNum => this.sceneNumInput;
                } else if (dataType == ComposerInputType.SET_SCENE.id) {
                    value$int => int triggerValue;

                    // Reset to 0.
                    if (triggerValue < 1.) {
                        0 => this.setSceneTrigger;
                        continue;
                    }

                    // Only trigger if value not already high
                    if (triggerValue >= 1. && this.setSceneTrigger == 1) continue;

                    1 => this.setSceneTrigger;
                    if (this.sceneNumInput < 0.) {
                        <<< "ERROR: Trying to set a negative scene", this.sceneNumInput >>>;
                        continue;
                    }

                    this.updateMeasures(this.sceneNumInput, 1);
                } else if (dataType == ComposerInputType.QUEUE_SCENE.id) {
                    value$int => int triggerValue;

                    // Reset to 0.
                    if (triggerValue < 1.) {
                        0 => this.queueSceneTrigger;
                        continue;
                    }

                    // Only trigger if value not already high
                    if (triggerValue >= 1. && this.queueSceneTrigger == 1) continue;

                    // Skip if already queued
                    if (this.sceneNumInput == this.queuedScene) continue;

                    // Queue the scene
                    this.sceneNumInput => this.queuedScene;
                }
            }
            10::ms => now;
        }
    }

    fun void processSceneChanges() {
        while (this.nodeActive) {
            if (this.scorePlayer != null) {
                // Check if there's a queued scene + score player isn't playing
                if (!this.scorePlayer.isPlaying() && this.queuedScene != -1) {
                    this.setActiveScene(this.queuedScene);
                    -1 => this.queuedScene;
                }
            }
            1::ms => now;
        }
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        // Button data
        data.set("numButtons", this.nodeButtonBox.buttons.size());

        // Score data
        data.set("activeScene", this.activeScene);

        // ComposeBox data
        HashMap filePathData;
        for (int boxIdx; boxIdx < this.composeBoxes.size(); boxIdx++) {
            this.composeBoxes[boxIdx] @=> ComposeBox composeBox;
            filePathData.set(boxIdx, composeBox.openedFilePath);
        }

        data.set("filePathData", filePathData);

        return data;
    }
}
