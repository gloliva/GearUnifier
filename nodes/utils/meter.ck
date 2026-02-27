@import "../base.ck"
@import "HashMap"


public class MeterNodeInputType {
    new Enum(0, "-") @=> static Enum NO_CONNECTION;

    [
        MeterNodeInputType.NO_CONNECTION,
    ] @=> static Enum allTypes[];
}


public class MeterNode extends Node {

    fun @construct()  {
        MeterNode(1, 4.);
    }

    fun @construct(int numInputs, float xScale) {
        // Set name and Node ID
        "Meter-Node" => this.name;
        this.setNodeID();

        // Node name box
        new NameBox("Meter", xScale) @=> this.nodeNameBox;

        // Create inputs box
        MeterNodeInputType.allTypes @=> this.inputTypes;
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(numInputs, MeterNodeInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;

        for (int idx; idx < numInputs; idx++) {
            this.nodeInputsBox.setInput(MeterNodeInputType.NO_CONNECTION, idx);
        }

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeInputsModifierBox --> this;
        this.nodeInputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();

        // Shreds
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        this.addShreds([processInputsShred]);
    }

    fun void addJack(int ioType) {
        super.addJack(ioType);
        this.nodeInputsBox.setInput(MeterNodeInputType.NO_CONNECTION, this.nodeInputsBox.numJacks - 1);
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.setMenuDisplayText(MeterNodeInputType.NO_CONNECTION.name, inputJackIdx);
    }

    fun void processInputs() {
        while (this.nodeActive) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                // Check if there is a connection at this jack
                this.nodeInputsBox.getJackUGen(idx) @=> UGen ugen;
                if (ugen == null) continue;

                // Input value from ugen
                this.getValueFromUGen(ugen) => float value;
                "" + value => string menuText;

                // Update the menu to display the value
                this.nodeInputsBox.setMenuDisplayText(menuText, idx);
            }

            10::ms => now;
        }
    }
}
