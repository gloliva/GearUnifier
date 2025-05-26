@import "../utils.ck"
@import "base.ck"
@import "HashMap"
@import "smuck"


public class SequencerInputType {
    new Enum(0, "Run") @=> static Enum RUN;

    [
        SequencerInputType.RUN,
    ] @=> static Enum allTypes[];
}


public class SequencerOutputType {
    new Enum(0, "Seq Out") @=> static Enum SEQ_OUT;

    [
        SequencerOutputType.SEQ_OUT,
    ] @=> static Enum allTypes[];
}


public class Sequencer extends Node {
    ezScorePlayer scorePlayer;

    fun @construct() {
        Sequencer(1, 4.);
    }

    fun @construct(int numInputs, float xScale) {
        // Set node ID and name
        "Sequencer Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Sequencer", xScale) @=> this.nodeNameBox;

        // Create options box

        // Create inputs box
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(numInputs, SequencerInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;

        // Create outputs box
        new IOBox(1, SequencerOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(SequencerOutputType.SEQ_OUT.id);

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

    fun void addJack(int ioType) {
         if (ioType == IOType.INPUT) {
            this.nodeInputsBox.addJack(SequencerOutputType.allTypes);
        }
        this.updatePos();
    }

    fun void removeJack(int ioType) {
        if (ioType == IOType.INPUT) {
            this.nodeInputsBox.removeJack();
        }
        this.updatePos();
    }

    fun HashMap serialize() {
        HashMap data;

        // Node data
        data.set("nodeClass", Type.of(this).name());
        data.set("nodeID", this.nodeID);
        data.set("posX", this.posX());
        data.set("posY", this.posY());
        data.set("posZ", this.posZ());
        data.set("numInputs", this.nodeInputsBox.numJacks);

        // Input menu data
        HashMap inputMenuData;
        for (int idx; idx < this.nodeInputsBox.menus.size(); idx++) {
            this.nodeInputsBox.menus[idx] @=> DropdownMenu menu;
            inputMenuData.set(idx, menu.getSelectedEntry().id);
        }
        data.set("inputMenuData", inputMenuData);

        return data;
    }
}
