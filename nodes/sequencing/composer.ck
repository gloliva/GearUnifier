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
    new Enum(1, "Set Scene") @=> static Enum SET_SCENE;
    new Enum(2, "Queue Scene") @=> static Enum QUEUE_SCENE;
    new Enum(3, "Tuning") @=> static Enum TUNING;

    [
        ComposerInputType.PLAYER,
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

    // smuck score parameters
    -1 => int activeScene;
    ezPart part;
    ComposerInstrument @ instrument;
    ScorePlayerNode @ scorePlayer;

    // Outs
    Step outs[];

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
            this.instrument.envOut,
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
        this.nodeOutputsBox.setOutput(ComposerOutputType.ENVELOPE, 1, this.instrument.envOut);

        // Create button box
        new IOModifierBox(xScale) @=> this.nodeButtonModifierBox;
        new ButtonBox(numStartButtons, xScale) @=> this.nodeButtonBox;

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Add compose boxes
        for (int idx; idx < numStartButtons; idx++) {
            ComposeBox composeBox("Scene " + (idx + 1), 18, 13);
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
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        this.addShreds([processInputsShred]);
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

    }

    fun void addButton() {
        this.nodeButtonBox.addButton();
        ComposeBox composeBox("Scene " + (this.composeBoxes.size() + 1), 18, 13);
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

    fun void processInputs() {
        while (this.nodeActive) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                // Check if this input jack has an associated data type
                this.nodeInputsBox.getDataTypeMapping(idx) => int dataType;
                if (dataType == -1) continue;

                // Get UGen connected to this input jack
                this.nodeInputsBox.jacks[idx].ugen @=> UGen ugen;
                if (ugen == null) continue;

                // Input value from ugen
                this.getValueFromUGen(ugen) => float value;

                // Change scenes by input values
                if (dataType == ComposerInputType.SET_SCENE.id) {
                    value$int => int sceneIdx;
                    if (sceneIdx < 0 || sceneIdx >= this.composeBoxes.size()) {
                        <<< "ERROR: Trying to set scene #", sceneIdx, "for number of scenes:", this.composeBoxes.size() >>>;
                        continue;
                    }

                    // Check if already set to incoming value
                    if (sceneIdx == this.activeScene) continue;

                    this.composeBoxes[sceneIdx].measures @=> ezMeasure measures[];

                    // Check that there are parsed measures
                    if (measures == null) {
                        <<< "IDK what to do here" >>>;  // TODO: some kind of error handling
                    }

                    // Set the measures for this part
                    <<< "Setting new active scene:", sceneIdx >>>;
                    sceneIdx => this.activeScene;
                    this.part.measures(measures);
                } else if (dataType == ComposerInputType.QUEUE_SCENE.id) {

                }
            }
            10::ms => now;
        }
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        // Button data
        data.set("numButtons", this.nodeButtonBox.buttons.size());

        return data;
    }
}
