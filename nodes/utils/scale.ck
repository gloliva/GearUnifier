@import "../../utils.ck"
@import "../base.ck"
@import "HashMap"

public class ScaleInputType {
    new Enum(0, "Wave In") @=> static Enum WAVE_IN;

    [
        ScaleInputType.WAVE_IN,
    ] @=> static Enum allTypes[];
}

public class ScaleOutputType {
    new Enum(0, "Wave Out") @=> static Enum WAVE_OUT;

    [
        ScaleOutputType.WAVE_OUT,
    ] @=> static Enum allTypes[];
}


public class Scale extends Chugen {
    -0.5 => float inLow;
    0.5 => float inHigh;
    float outLow;
    float outHigh;

    fun void setInLow(float low) {
        low => this.inLow;
    }

    fun void setInHigh(float high) {
        high => this.inHigh;
    }

    fun void setOutLow(float low) {
        low => this.outLow;
    }

    fun void setOutHigh(float high) {
        high => this.outHigh;
    }

    fun float tick(float in) {
        Std.scalef(in, this.inLow, this.inHigh, this.outLow, this.outHigh) => float out;
        // <<< "In ", in, "Out ", out >>>;
        return out;
    }
}


public class ScaleNode extends Node {
    Scale scale;

    fun @construct() {
        ScaleNode(1, 4.);
    }

    fun @construct(int numInputs, float xScale) {
        // Set node ID and name
        "Scale Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Scale", xScale) @=> this.nodeNameBox;

        // Create options box

        // Create inputs box
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(numInputs, ScaleInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;

        // Create outputs box
        new IOBox(1, ScaleOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(ScaleOutputType.WAVE_OUT.id);
        this.nodeOutputsBox.jacks[0].setUgen(this.scale);

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeInputsModifierBox --> this;
        this.nodeInputsBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();

        // TODO: remove after testing
        0. => this.scale.setOutLow;
        1. => this.scale.setOutHigh;
    }

    fun void connect(UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "Scale Connect: No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == ScaleInputType.WAVE_IN.id) {
            ugen => this.scale;
        }
    }

    fun void disconnect(UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "Scale Disconnect: No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == ScaleInputType.WAVE_IN.id) {
            ugen =< this.scale;
        }
    }
}
