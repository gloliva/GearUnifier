@import "../../utils.ck"
@import "../sequencing/transport.ck"
@import {"../base.ck", "../tuning.ck"}
@import "HashMap"


public class RandomPitchInputType {
    new Enum(0, "Transport") @=> static Enum TRANSPORT;
    new Enum(1, "Tuning") @=> static Enum TUNING;

    [
        RandomPitchInputType.TRANSPORT,
        RandomPitchInputType.TUNING,
    ] @=> static Enum allTypes[];
}


public class RandomPitchOuputType {
    new Enum(0, "Pitch") @=> static Enum PITCH;

    [
        RandomPitchOuputType.PITCH,
    ] @=> static Enum allTypes[];
}


public class RandomPitch extends Node {
    // Tuning
    Tuning @ tuning;

    // Beat
    Event @ beat;
    -1 => int beatShredId;

    fun @construct() {
        RandomPitch(4.);
    }

    fun @construct(float xScale) {
        new EDO(12, 0) @=> this.tuning;

        // Set name and Node ID
        "Random-Pitch-Node" => this.name;
        this.setNodeID();

        // Node name box
        new NameBox("Random Pitch", xScale) @=> this.nodeNameBox;

        // Create inputs box
        new IOBox(2, RandomPitchInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        this.nodeInputsBox.setInput(RandomPitchInputType.TRANSPORT, 0);
        this.nodeInputsBox.setInput(RandomPitchInputType.TUNING, 1);

        // Create outputs box
        new IOBox(1, RandomPitchOuputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.setOutput(RandomPitchOuputType.PITCH, 0);

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeInputsBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();
    }

    fun void outputPitchOnBeat() {
        while (this.nodeActive) {
            this.beat => now;
            Math.random2(0, this.tuning.scaleSize) => int degree;
            this.tuning.cv(degree) => this.nodeOutputsBox.outs(RandomPitchOuputType.PITCH).next;
        }
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == RandomPitchInputType.TRANSPORT.id && Type.of(outputNode).name() == TransportNode.typeOf().name()) {
            (outputNode$TransportNode).beat @=> this.beat;
            spork ~ this.outputPitchOnBeat() @=> Shred outputPitchOnBeatShred;
            outputPitchOnBeatShred.id() => this.beatShredId;
        } else if (dataType == RandomPitchInputType.TUNING.id) {
            if (Type.of(outputNode).name() == ScaleTuningNode.typeOf().name()) {
                (outputNode$ScaleTuningNode).tuning @=> this.tuning;
            } else if (Type.of(outputNode).name() == EDOTuningNode.typeOf().name()) {
                (outputNode$EDOTuningNode).tuning @=> this.tuning;
            }
        }
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == RandomPitchInputType.TRANSPORT.id && Type.of(outputNode).name() == TransportNode.typeOf().name()) {
            null @=> this.beat;
            Machine.remove(this.beatShredId);
            -1 => this.beatShredId;
        } else if (dataType == RandomPitchInputType.TUNING.id) {
            new EDO(12, 0) @=> this.tuning;
        }
    }

    fun void deactivateNode() {
        // Remove OutputBeat shred
        if (this.beatShredId != -1) Machine.remove(this.beatShredId);
        super.deactivateNode();
    }
}
