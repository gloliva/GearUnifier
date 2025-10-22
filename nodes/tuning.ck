@import {"../events.ck", "../utils.ck"}
@import {"../tuning/base.ck", "../tuning/scalaFileParser.ck"}
@import "../ui/textBox.ck"
@import "base.ck"
@import "HashMap"


public class TuningOutputType {
    new Enum(0, "Tuning") @=> static Enum TUNING;

    [
        TuningOutputType.TUNING,
    ] @=> static Enum allTypes[];
}


public class ScaleTuningNode extends Node {
    ScaleTuning @ tuning;

}


public class EDOTuningOptionsBox extends OptionsBox {
    // Number Entry Boxes
    NumberEntryBox @ scaleSizeEntryBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Number Entry Boxes
        new NumberEntryBox(4, 0, NumberBoxType.INT, 2.) @=> this.scaleSizeEntryBox;

        // Set Events
        this.scaleSizeEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.scaleSizeEntryBox.pos;

        // Name
        "ScaleSize NumberEntryBox" => this.scaleSizeEntryBox.name;

        // Connections
        this.scaleSizeEntryBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$EDOTuningNode @=> EDOTuningNode parentNode;

        // Check if Tempo clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.scaleSizeEntryBox, this.scaleSizeEntryBox.box])) {
            1 => entryBoxSelected;
            this.scaleSizeEntryBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
    }
}


public class EDOTuningNode extends Node {
    int scaleSize;
    EDO @ tuning;

    fun @construct() {
        EDOTuningNode(4.);
    }

    fun @construct(float xScale) {
        // Default to 12 TET
        12 => this.scaleSize;
        new EDO(this.scaleSize, -48) @=> this.tuning;

        // Set node ID and name
        "EDO Tuning Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("EDO Tuning", xScale) @=> this.nodeNameBox;

        // Create options box
        new EDOTuningOptionsBox(["Size"], xScale) @=> this.nodeOptionsBox;
        (this.nodeOptionsBox$EDOTuningOptionsBox).scaleSizeEntryBox.set(this.scaleSize);

        // Create outputs box
        new IOBox(1, TuningOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(TuningOutputType.TUNING.id);

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeOptionsBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();
    }

    fun void processOptions() {
        this.nodeOptionsBox$EDOTuningOptionsBox @=> EDOTuningOptionsBox optionsBox;

        while (this.nodeActive) {
            optionsBox.updateNumberEntryBoxEvent => now;

            optionsBox.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx ;
            optionsBox.updateNumberEntryBoxEvent.numberBoxValue => int numberBoxValue ;

            if (numberBoxIdx == 0) {
                numberBoxValue => this.scaleSize;
            }

            this.scaleSize => this.tuning.setDivisions;
        }
    }

    fun HashMap serialize() {
        HashMap data;
        data.set("nodeClass", Type.of(this).name());
        data.set("nodeID", this.nodeID);
        data.set("scaleSize", this.scaleSize);
        data.set("posX", this.posX());
        data.set("posY", this.posY());
        data.set("posZ", this.posZ());

        return data;
    }
}
