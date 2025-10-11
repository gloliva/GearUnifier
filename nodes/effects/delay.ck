// Imports
@import "../../utils.ck"
@import "../../ui/menu.ck"
@import "../base.ck"
@import "HashMap"


public class DelayInputType {
    new Enum(0, "Wave In") @=> static Enum WAVE_IN;
    new Enum(1, "Delay") @=> static Enum DELAY;
    new Enum(2, "Feedback") @=> static Enum FEEDBACK;
    new Enum(3, "Dry") @=> static Enum DRY;

    [
        DelayInputType.WAVE_IN,
        DelayInputType.DELAY,
        DelayInputType.FEEDBACK,
        DelayInputType.DRY,
    ] @=> static Enum allTypes[];
}


public class DelayOptionsBox extends OptionsBox {
    // Number Entry Boxes
    NumberEntryBox @ delayEntryBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;


    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Number Entry Boxes
        new NumberEntryBox(4, 0, NumberBoxType.INT, 2.) @=> this.delayEntryBox;

        // Set Events
        this.delayEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.delayEntryBox.pos;

        // Name
        "Delay NumberEntryBox" => this.delayEntryBox.name;

        // Connections
        this.delayEntryBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$DelayNode @=> DelayNode parentNode;

        // Check if In Low clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.delayEntryBox, this.delayEntryBox.box])) {
            1 => entryBoxSelected;
            this.delayEntryBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
    }
}


public class DelayNode extends Node {
    Gain out;
    Gain dryGain;
    Gain delayGain;
    Delay delay(250::ms, 2::second);
    Gain feedback;

    250::ms => dur delayTime;
    0.5 => float feedbackAmount;
    0.5 => float dry;

    fun @construct() {
        DelayNode(1, 4.);
    }

    fun @construct(int numInputs, float xScale) {
        // Set node ID and name
        "Delay Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Delay", xScale) @=> this.nodeNameBox;

        // Create options box
        new DelayOptionsBox(["Delay MS"], xScale) @=> this.nodeOptionsBox;
        (this.nodeOptionsBox$DelayOptionsBox).delayEntryBox.set(delayTime / 1::ms);

        // Create inputs box
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(numInputs, DelayInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;

        // Create outputs box
        new IOBox(1, [new Enum(0, "Wave Out")], IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(0);
        this.nodeOutputsBox.jacks[0].setUgen(this.out);

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Create Delay and Feedback UGen chaining
        this.delayGain => this.delay => this.out;
        this.dryGain => this.out;
        this.delay => this.feedback => this.delay;

        // Set gains and delay parameters
        1. => this.out.gain;
        this.dry => this.dryGain.gain;
        (1. - this.dry) => this.delayGain.gain;
        this.feedbackAmount => this.feedback.gain;

        this.delayTime => this.delay.delay;
        2::second => this.delay.max;

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

    fun void setDelay(dur delay) {
        delay => this.delayTime;
        <<< "Setting delay: ", this.delayTime / 1::ms >>>;
        this.delayTime => this.delay.delay;
    }

    fun void setFeedback(float feedback) {
        feedback => this.feedbackAmount;
        this.feedbackAmount => this.feedback.gain;
    }

    fun void setDry(float dry) {
        dry => this.dry;
        this.dry => this.dryGain.gain;
        (1. - this.dry) => this.delayGain.gain;
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == DelayInputType.WAVE_IN.id) {
            ugen => this.delayGain;
            ugen => this.dryGain;
        }

    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        // Remove any additional mappings
        if (dataType == DelayInputType.WAVE_IN.id) {
            ugen =< this.delayGain;
            ugen =< this.dryGain;
        }
    }

    fun void addJack(int ioType) {
         if (ioType == IOType.INPUT) {
            this.nodeInputsBox.addJack(DelayInputType.allTypes);
        }
        this.updatePos();
    }

    fun void removeJack(int ioType) {
        if (ioType == IOType.INPUT) {
            this.nodeInputsBox.removeJack() @=> Enum removedMenuSelection;
        }
        this.updatePos();
    }

    fun void processInputs() {
        while (this.nodeActive) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                this.nodeInputsBox.getDataTypeMapping(idx) => int dataType;
                if (dataType == -1) continue;

                // Value can be from a audio rate UGen (which uses last()) or a control rate UGen (which uses next())
                this.nodeInputsBox.jacks[idx].ugen @=> UGen ugen;
                if (ugen == null) {
                    continue;
                }

                float value;
                if (Type.of(ugen).name() == Step.typeOf().name()) {
                    (ugen$Step).next() => value;
                } else {
                    ugen.last() => value;
                }

                if (dataType == DelayInputType.DELAY.id) {
                    Std.scalef(value, -0.5, 0.5, 10., 1000.) => float delayMsValue;
                    delayMsValue::ms => this.setDelay;
                } else if (dataType == DelayInputType.FEEDBACK.id) {
                    Std.scalef(value, -0.5, 0.5, 0., 0.95) => this.setFeedback;
                } else if (dataType == DelayInputType.DRY.id) {
                    Std.scalef(value, -0.5, 0.5, 0., 1.) => this.setDry;
                }
            }
            10::ms => now;
        }
    }

    fun void processOptions() {
        this.nodeOptionsBox$DelayOptionsBox @=> DelayOptionsBox optionsBox;

        while (this.nodeActive) {
            optionsBox.updateNumberEntryBoxEvent => now;

            optionsBox.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx ;
            optionsBox.updateNumberEntryBoxEvent.numberBoxValue => int numberBoxValue ;

            if (numberBoxIdx == 0) {
                numberBoxValue::ms => this.setDelay;
            }
        }
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

        // Wavefolder parameters
        data.set("delayTime", this.delayTime / 1::ms);
        data.set("feedbackAmount", this.feedbackAmount);
        data.set("dry", this.dry);

        return data;
    }
}
