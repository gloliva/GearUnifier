@import "../../events.ck"
@import "../../utils.ck"
@import "../../ui/textBox.ck"
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
    -0.5 => float outLow;
    0.5 => float outHigh;

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
        return out;
    }
}


public class ScaleOptionsBox extends OptionsBox {
    // Number Entry Boxes
    NumberEntryBox @ inLowEntryBox;
    NumberEntryBox @ inHighEntryBox;
    NumberEntryBox @ outLowEntryBox;
    NumberEntryBox @ outHighEntryBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;


    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Number Entry Boxes
        new NumberEntryBox(6, 0, NumberBoxType.FLOAT, 2.) @=> this.inLowEntryBox;
        new NumberEntryBox(6, 1, NumberBoxType.FLOAT, 2.) @=> this.inHighEntryBox;
        new NumberEntryBox(6, 2, NumberBoxType.FLOAT, 2.) @=> this.outLowEntryBox;
        new NumberEntryBox(6, 3, NumberBoxType.FLOAT, 2.) @=> this.outHighEntryBox;

        // Set Events
        this.inLowEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.inHighEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.outLowEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.outHighEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.inLowEntryBox.pos;
        @(0.75, this.optionNames[1].posY(), 0.201) => this.inHighEntryBox.pos;
        @(0.75, this.optionNames[2].posY(), 0.201) => this.outLowEntryBox.pos;
        @(0.75, this.optionNames[3].posY(), 0.201) => this.outHighEntryBox.pos;

        // Name
        "In Low NumberEntryBox" => this.inLowEntryBox.name;
        "In High NumberEntryBox" => this.inHighEntryBox.name;
        "Out Low NumberEntryBox" => this.outLowEntryBox.name;
        "Out High NumberEntryBox" => this.outHighEntryBox.name;

        // Connections
        this.inLowEntryBox --> this;
        this.inHighEntryBox --> this;
        this.outLowEntryBox --> this;
        this.outHighEntryBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$ScaleNode @=> ScaleNode parentNode;

        // Check if In Low clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.inLowEntryBox, this.inLowEntryBox.box])) {
            1 => entryBoxSelected;
            this.inLowEntryBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if In High clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.inHighEntryBox, this.inHighEntryBox.box])) {
            1 => entryBoxSelected;
            this.inHighEntryBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if Out Low clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.outLowEntryBox, this.outLowEntryBox.box])) {
            1 => entryBoxSelected;
            this.outLowEntryBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if Out High clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.outHighEntryBox, this.outHighEntryBox.box])) {
            1 => entryBoxSelected;
            this.outHighEntryBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
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
        new ScaleOptionsBox(["In Low", "In High", "Out Low", "Out High"], xScale) @=> this.nodeOptionsBox;

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
        this.nodeOptionsBox --> this;
        this.nodeInputsModifierBox --> this;
        this.nodeInputsBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();
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

    fun void processOptions() {
        this.nodeOptionsBox$ScaleOptionsBox @=> ScaleOptionsBox optionsBox;

        while (true) {
            optionsBox.updateNumberEntryBoxEvent => now;

            optionsBox.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx ;
            optionsBox.updateNumberEntryBoxEvent.numberBoxFloatValue => float numberBoxFloatValue ;

            if (numberBoxIdx == 0) {
                numberBoxFloatValue => this.scale.setInLow;
            } else if (numberBoxIdx == 1) {
                numberBoxFloatValue => this.scale.setInHigh;
            } else if (numberBoxIdx == 2) {
                numberBoxFloatValue => this.scale.setOutLow;
            } else if (numberBoxIdx == 3) {
                numberBoxFloatValue => this.scale.setOutHigh;
            }

        }
    }
}
