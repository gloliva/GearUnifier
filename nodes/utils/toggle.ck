@import "../../utils.ck"
@import "../base.ck"
@import "HashMap"


public class ToggleInputType {
    new Enum(0, "Signal In") @=> static Enum SIGNAL_IN;

    [
        ToggleInputType.SIGNAL_IN,
    ] @=> static Enum allTypes[];
}


public class ToggleOutputType {
    new Enum(0, "Toggle Out") @=> static Enum TOGGLE_OUT;

    [
        ToggleOutputType.TOGGLE_OUT,
    ] @=> static Enum allTypes[];
}


public class ToggleNode extends Node {
    fun @construct() {
        ToggleNode(4.);
    }

    fun @construct(float xScale) {
        // Set node ID and name
        "Toggle-Node" => this.name;
        this.setNodeID();

        // Node name box
        new NameBox("Toggle", xScale) @=> this.nodeNameBox;

        // Create inputs box
        ToggleInputType.allTypes @=> this.inputTypes;
        new IOBox(1, ToggleInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        this.nodeInputsBox.setInput(ToggleInputType.SIGNAL_IN, 0);

        // Create outputs box
        ToggleOutputType.allTypes @=> this.outputTypes;
        new IOBox(1, ToggleOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.setOutput(ToggleOutputType.TOGGLE_OUT, 0);

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

        // Shreds
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        this.addShreds([processInputsShred]);
    }

    fun void processInputs() {
        0. => float prevVal;
        0. => float thresh;
        0 => int wasHigh;

        while (this.nodeActive) {

            // Fixed number of input jacks, only need to check SIGNAL_IN
            this.nodeInputsBox.getJackUGen(ToggleInputType.SIGNAL_IN.id) @=> UGen ugen;
            if (ugen != null) {
                // Input value from ugen
                this.getValueFromUGen(ugen) => float value;

                if (value > thresh && !wasHigh) {
                    1 => wasHigh;
                    0.5 - prevVal => float nextVal;
                    nextVal => this.nodeOutputsBox.outs(ToggleOutputType.TOGGLE_OUT).next;
                    nextVal => prevVal;
                } else if (value <= thresh && wasHigh) {
                    0 => wasHigh;
                }
            }

            10::ms => now;
        }
    }
}