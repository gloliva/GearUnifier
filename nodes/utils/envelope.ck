@import {"../../events.ck", "../../utils.ck"}
@import "../../ui/textBox.ck"
@import "../base.ck"
@import "HashMap"


public class EnvelopeInputType {
    new Enum(0, "Gate In") @=> static Enum GATE_IN;

    [
        EnvelopeInputType.GATE_IN,
    ] @=> static Enum allTypes[];
}


public class EnvelopeOutputType {
    new Enum(0, "Env Out") @=> static Enum ENV_OUT;

    [
        EnvelopeOutputType.ENV_OUT,
    ] @=> static Enum allTypes[];
}


public class ASROptionsBox extends OptionsBox {
    // Number Entry Boxes
    NumberEntryBox @ attackTimeBox;
    NumberEntryBox @ sustainLevelBox;
    NumberEntryBox @ releaseTimeBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Number Entry Boxes
        new NumberEntryBox(8, 0, NumberBoxType.FLOAT, 2.) @=> this.attackTimeBox;
        new NumberEntryBox(8, 1, NumberBoxType.FLOAT, 2.) @=> this.sustainLevelBox;
        new NumberEntryBox(8, 2, NumberBoxType.FLOAT, 2.) @=> this.releaseTimeBox;

        // Set Events
        this.attackTimeBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.sustainLevelBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.releaseTimeBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.attackTimeBox.pos;
        @(0.75, this.optionNames[1].posY(), 0.201) => this.sustainLevelBox.pos;
        @(0.75, this.optionNames[2].posY(), 0.201) => this.releaseTimeBox.pos;

        // Name
        "AttackTime NumberEntryBox" => this.attackTimeBox.name;
        "SustainLevel NumberEntryBox" => this.sustainLevelBox.name;
        "ReleaseTime NumberEntryBox" => this.releaseTimeBox.name;

        // Connections
        this.attackTimeBox --> this;
        this.sustainLevelBox --> this;
        this.releaseTimeBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$ASRNode @=> ASRNode parentNode;

        // Check if AttackTime clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.attackTimeBox, this.attackTimeBox.box])) {
            1 => entryBoxSelected;
            this.attackTimeBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if SustainLevel clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.sustainLevelBox, this.sustainLevelBox.box])) {
            1 => entryBoxSelected;
            this.sustainLevelBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if ReleaseTime clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.releaseTimeBox, this.releaseTimeBox.box])) {
            1 => entryBoxSelected;
            this.releaseTimeBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
    }
}


public class ASRNode extends Node {
    // ASR values
    dur attackTime;
    float sustainLevel;
    dur releaseTime;

    Envelope env;
    Step out(0.);
    int active;

    fun @construct() {
        ASRNode(250::ms, 0.7, 1::second, 4.);
    }

    fun @construct(dur attackTime, float sustainLevel, dur releaseTime, float xScale) {
        // Set ASR parameters
        this.env => blackhole;
        attackTime => this.attackTime;
        sustainLevel => this.sustainLevel;
        releaseTime => this.releaseTime;

        // Set node ID and name
        "ASR Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("ASR", xScale) @=> this.nodeNameBox;

        // Create options box
        new ASROptionsBox(["Attack", "Sustain", "Release"], xScale) @=> this.nodeOptionsBox;
        (this.nodeOptionsBox$ASROptionsBox).attackTimeBox.set(attackTime / 1::ms);
        (this.nodeOptionsBox$ASROptionsBox).sustainLevelBox.set(sustainLevel);
        (this.nodeOptionsBox$ASROptionsBox).releaseTimeBox.set(releaseTime / 1::ms);

        // Create inputs box
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(1, EnvelopeInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        this.nodeInputsBox.menus[0].updateSelectedEntry(EnvelopeInputType.GATE_IN.id);
        this.nodeInputsBox.setDataTypeMapping(EnvelopeInputType.GATE_IN, 0);

        // Create outputs box
        new IOBox(1, EnvelopeOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(EnvelopeOutputType.ENV_OUT.id);
        this.nodeOutputsBox.jacks[0].setUgen(this.out);

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

        // Shreds
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        spork ~ this.processOptions() @=> Shred @ processOptionsShred;
        this.addShreds([processInputsShred, processOptionsShred]);
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "ASR Connect: No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == EnvelopeInputType.GATE_IN.id) {
            ugen => this.env;
        }
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "ASR Disconnect: No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == EnvelopeInputType.GATE_IN.id) {
            ugen =< this.env;
        }
    }

    fun void addJack(int ioType) {
         if (ioType == IOType.INPUT) {
            this.nodeInputsBox.addJack(EnvelopeInputType.allTypes);
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

                this.nodeInputsBox.jacks[idx].ugen @=> UGen ugen;
                if (ugen == null) {
                    continue;
                }

                this.getValueFromUGen(ugen) => float value;
                if (dataType == EnvelopeInputType.GATE_IN.id) {
                    // If value is above 0, then start envelope attack
                    if (value > 0. && !this.active) {
                        this.env.ramp(this.attackTime, this.sustainLevel);
                        1 => this.active;

                    // Else if value is 0 and envelope is active, start envelope release
                    } else if (value <= 0. && this.active) {
                        this.env.ramp(this.releaseTime, 0);
                        0 => this.active;
                    }
                }

                this.env.value() => this.out.next;
            }
            10::ms => now;
        }
    }

    fun void processOptions() {
        this.nodeOptionsBox$ASROptionsBox @=> ASROptionsBox optionsBox;

        while (this.nodeActive) {
            optionsBox.updateNumberEntryBoxEvent => now;

            optionsBox.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx ;
            optionsBox.updateNumberEntryBoxEvent.numberBoxFloatValue => float numberBoxFloatValue ;

            if (numberBoxIdx == 0) {
                numberBoxFloatValue::ms => this.attackTime;
            } else if (numberBoxIdx == 1) {
                numberBoxFloatValue => this.sustainLevel;
            } else if (numberBoxIdx == 2) {
                numberBoxFloatValue::ms => this.releaseTime;
            }
        }
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        data.set("attackTime", this.attackTime / 1::second);
        data.set("sustainLevel", this.sustainLevel);
        data.set("releaseTime", this.releaseTime / 1::second);

        return data;
    }
}


public class ADSROptionsBox extends OptionsBox {
    // Number Entry Boxes
    NumberEntryBox @ attackTimeBox;
    NumberEntryBox @ decayTimeBox;
    NumberEntryBox @ sustainLevelBox;
    NumberEntryBox @ releaseTimeBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Number Entry Boxes
        new NumberEntryBox(8, 0, NumberBoxType.FLOAT, 2.) @=> this.attackTimeBox;
        new NumberEntryBox(8, 1, NumberBoxType.FLOAT, 2.) @=> this.decayTimeBox;
        new NumberEntryBox(8, 2, NumberBoxType.FLOAT, 2.) @=> this.sustainLevelBox;
        new NumberEntryBox(8, 3, NumberBoxType.FLOAT, 2.) @=> this.releaseTimeBox;

        // Set Events
        this.attackTimeBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.decayTimeBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.sustainLevelBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.releaseTimeBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.attackTimeBox.pos;
        @(0.75, this.optionNames[1].posY(), 0.201) => this.decayTimeBox.pos;
        @(0.75, this.optionNames[2].posY(), 0.201) => this.sustainLevelBox.pos;
        @(0.75, this.optionNames[3].posY(), 0.201) => this.releaseTimeBox.pos;

        // Name
        "AttackTime NumberEntryBox" => this.attackTimeBox.name;
        "DecayTime NumberEntryBox" => this.decayTimeBox.name;
        "SustainLevel NumberEntryBox" => this.sustainLevelBox.name;
        "ReleaseTime NumberEntryBox" => this.releaseTimeBox.name;

        // Connections
        this.attackTimeBox --> this;
        this.decayTimeBox --> this;
        this.sustainLevelBox --> this;
        this.releaseTimeBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$ADSRNode @=> ADSRNode parentNode;

        // Check if AttackTime clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.attackTimeBox, this.attackTimeBox.box])) {
            1 => entryBoxSelected;
            this.attackTimeBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if DecayTime clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.decayTimeBox, this.decayTimeBox.box])) {
            1 => entryBoxSelected;
            this.decayTimeBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if SustainLevel clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.sustainLevelBox, this.sustainLevelBox.box])) {
            1 => entryBoxSelected;
            this.sustainLevelBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if ReleaseTime clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.releaseTimeBox, this.releaseTimeBox.box])) {
            1 => entryBoxSelected;
            this.releaseTimeBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
    }
}


public class ADSRNode extends Node {
    ADSR adsr;
    Step out(0.);
    int active;

    fun @construct() {
        ADSRNode(250::ms, 100::ms, 0.8, 1::second, 4.);
    }

    fun @construct(dur attackTime, dur decayTime, float sustainLevel, dur releaseTime, float xScale) {
        // Set ADSR parameters
        this.adsr => blackhole;
        this.adsr.set(attackTime, decayTime, sustainLevel, releaseTime);

        // Set node ID and name
        "ADSR Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("ADSR", xScale) @=> this.nodeNameBox;

        // Create options box
        new ADSROptionsBox(["Attack", "Decay", "Sustain", "Release"], xScale) @=> this.nodeOptionsBox;
        (this.nodeOptionsBox$ADSROptionsBox).attackTimeBox.set(attackTime / 1::ms);
        (this.nodeOptionsBox$ADSROptionsBox).decayTimeBox.set(decayTime / 1::ms);
        (this.nodeOptionsBox$ADSROptionsBox).sustainLevelBox.set(sustainLevel);
        (this.nodeOptionsBox$ADSROptionsBox).releaseTimeBox.set(releaseTime / 1::ms);

        // Create inputs box
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(1, EnvelopeInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        this.nodeInputsBox.menus[0].updateSelectedEntry(EnvelopeInputType.GATE_IN.id);
        this.nodeInputsBox.setDataTypeMapping(EnvelopeInputType.GATE_IN, 0);

        // Create outputs box
        new IOBox(1, EnvelopeOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(EnvelopeOutputType.ENV_OUT.id);
        this.nodeOutputsBox.jacks[0].setUgen(this.out);

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

        // Shreds
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        spork ~ this.processOptions() @=> Shred @ processOptionsShred;
        this.addShreds([processInputsShred, processOptionsShred]);
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "ADSR Connect: No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == EnvelopeInputType.GATE_IN.id) {
            ugen => this.adsr;
        }
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "ADSR Disconnect: No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == EnvelopeInputType.GATE_IN.id) {
            ugen =< this.adsr;
        }
    }

    fun void addJack(int ioType) {
         if (ioType == IOType.INPUT) {
            this.nodeInputsBox.addJack(EnvelopeInputType.allTypes);
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

                this.nodeInputsBox.jacks[idx].ugen @=> UGen ugen;
                if (ugen == null) {
                    continue;
                }

                this.getValueFromUGen(ugen) => float value;
                if (dataType == EnvelopeInputType.GATE_IN.id) {
                    // If value is above 0, then start envelope attack
                    if (value > 0. && !this.active) {
                        this.adsr.keyOn();
                        1 => this.active;

                    // Else if value is 0 and envelope is active, start envelope release
                    } else if (value <= 0. && this.active) {
                        this.adsr.keyOff();
                        0 => this.active;
                    }
                }

                this.adsr.value() => this.out.next;
            }
            10::ms => now;
        }
    }

    fun void processOptions() {
        this.nodeOptionsBox$ADSROptionsBox @=> ADSROptionsBox optionsBox;

        while (this.nodeActive) {
            optionsBox.updateNumberEntryBoxEvent => now;

            optionsBox.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx ;
            optionsBox.updateNumberEntryBoxEvent.numberBoxFloatValue => float numberBoxFloatValue ;

            if (numberBoxIdx == 0) {
                numberBoxFloatValue::ms => this.adsr.attackTime;
            } else if (numberBoxIdx == 1) {
                numberBoxFloatValue::ms => this.adsr.decayTime;
            } else if (numberBoxIdx == 2) {
                numberBoxFloatValue => this.adsr.sustainLevel;
            } else if (numberBoxIdx == 3) {
                numberBoxFloatValue::ms => this.adsr.releaseTime;
            }
        }
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        data.set("attackTime", this.adsr.attackTime() / 1::second);
        data.set("decayTime", this.adsr.decayTime() / 1::second);
        data.set("sustainLevel", this.adsr.sustainLevel());
        data.set("releaseTime", this.adsr.releaseTime() / 1::second);

        return data;
    }
}
