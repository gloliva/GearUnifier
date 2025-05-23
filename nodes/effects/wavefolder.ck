// Imports
@import "../../utils.ck"
@import "../base.ck"

public class WavefolderInputType {
    new Enum(0, "Wave In") @=> static Enum WAVE_IN;
    new Enum(1, "Threshold") @=> static Enum THRESHOLD;
    new Enum(2, "Gain") @=> static Enum GAIN;
    new Enum(3, "Mix") @=> static Enum MIX;

    [
        WavefolderInputType.WAVE_IN,
        WavefolderInputType.THRESHOLD,
        WavefolderInputType.GAIN,
        WavefolderInputType.MIX,
    ] @=> static Enum allTypes[];
}


public class WavefolderNode extends Node {
    fun @construct() {
        WavefolderNode(4.);
    }

    fun @construct(float xScale) {
        // Set node ID and name
        "Wavefolder Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Wavefolder", xScale) @=> this.nodeNameBox;

        // Create options box

        // Create inputs box
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(1, WavefolderInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;

        // Create outputs box
        new IOBox(1, [new Enum(0, "Wave Out")], IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;

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
    }
}
