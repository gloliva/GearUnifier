@import "../../events.ck"
@import "../../utils.ck"
@import "../../ui/textBox.ck"
@import "../base.ck"
@import "HashMap"


public class TransportInputType {
    new Enum(0, "Clock In") @=> static Enum CLOCK;

    [
        TransportInputType.CLOCK,
    ] @=> static Enum allTypes[];
}


public class TransportOutputType {
    new Enum(0, "Sync") @=> static Enum SYNC;
    new Enum(1, "Beat Out") @=> static Enum BEAT;
    new Enum(2, "Clock Out") @=> static Enum CLOCK;

    [
        TransportOutputType.SYNC,
        TransportOutputType.BEAT,
        TransportOutputType.CLOCK,
    ] @=> static Enum allTypes[];
}


public class TransportOptionsBox extends OptionsBox {
    // Number Entry Boxes
    NumberEntryBox @ tempoEntryBox;
    NumberEntryBox @ beatDivEntryBox;
    NumberEntryBox @ PPQNEntryBox;
    NumberEntryBox @ thresholdEntryBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Number Entry Boxes
        new NumberEntryBox(3, 0, NumberBoxType.INT, 2.) @=> this.tempoEntryBox;
        new NumberEntryBox(6, 1, NumberBoxType.FLOAT, 2.) @=> this.beatDivEntryBox;
        new NumberEntryBox(3, 2, NumberBoxType.INT, 2.) @=> this.PPQNEntryBox;
        new NumberEntryBox(4, 3, NumberBoxType.FLOAT, 2.) @=> this.thresholdEntryBox;

        // Set Events
        this.tempoEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.beatDivEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.PPQNEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.thresholdEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.tempoEntryBox.pos;
        @(0.75, this.optionNames[1].posY(), 0.201) => this.beatDivEntryBox.pos;
        @(0.75, this.optionNames[2].posY(), 0.201) => this.PPQNEntryBox.pos;
        @(0.75, this.optionNames[3].posY(), 0.201) => this.thresholdEntryBox.pos;

        // Name
        "Tempo NumberEntryBox" => this.tempoEntryBox.name;
        "Beat Divider NumberEntryBox" => this.beatDivEntryBox.name;
        "PPQN NumberEntryBox" => this.PPQNEntryBox.name;
        "Threshold NumberEntryBox" => this.thresholdEntryBox.name;

        // Connections
        this.tempoEntryBox --> this;
        this.beatDivEntryBox --> this;
        this.PPQNEntryBox --> this;
        this.thresholdEntryBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$TransportNode @=> TransportNode parentNode;

        // Check if Tempo clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.tempoEntryBox, this.tempoEntryBox.box])) {
            1 => entryBoxSelected;
            this.tempoEntryBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if Beat Divider clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.beatDivEntryBox, this.beatDivEntryBox.box])) {
            1 => entryBoxSelected;
            this.beatDivEntryBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if PPQN clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.PPQNEntryBox, this.PPQNEntryBox.box])) {
            1 => entryBoxSelected;
            this.PPQNEntryBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
    }
}


public class TransportNode extends Node {
    float tempo;
    float beatDiv;
    int PPQN;
    float threshold;

    // External Clock
    UGen @ externalClock;
    Event syncToExternalClock;
    int externalClockConnected;

    fun @construct() {
        TransportNode(120., 1., 4.);
    }

    fun @construct(float xScale) {
        TransportNode(120., 1., xScale);
    }

    fun @construct(float tempo, float beatDiv, float xScale) {
        TransportNode(1, tempo, beatDiv, 24, 0.4, xScale);
    }

    fun @construct(int numOutputs, float tempo, float beatDiv, int ppqn, float threshold, float xScale) {
        // Initialize tempo variables
        tempo => this.tempo;
        beatDiv => this.beatDiv;
        ppqn => this.PPQN;
        threshold => this.threshold;

        // Set node ID and name
        "Transport-Node" => this.name;
        this.setNodeID();

        // Node name box
        new NameBox("Transport", xScale) @=> this.nodeNameBox;

        // Create options box
        new TransportOptionsBox(["Tempo", "Beat X", "PPQN", "Thresh"], xScale) @=> this.nodeOptionsBox;
        (this.nodeOptionsBox$TransportOptionsBox).tempoEntryBox.set(Std.ftoi(tempo));
        (this.nodeOptionsBox$TransportOptionsBox).beatDivEntryBox.set(beatDiv);
        (this.nodeOptionsBox$TransportOptionsBox).PPQNEntryBox.set(ppqn);
        (this.nodeOptionsBox$TransportOptionsBox).thresholdEntryBox.set(threshold);

        // Create inputs box
        TransportInputType.allTypes @=> this.inputTypes;
        new IOBox(1, TransportInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        this.nodeInputsBox.setInput(TransportInputType.CLOCK, 0);

        // Create outputs box
        TransportOutputType.allTypes @=> this.outputTypes;
        new IOModifierBox(xScale) @=> this.nodeOutputsModifierBox;
        new IOBox(numOutputs, TransportOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.updateSync() => this.nodeOutputsBox.outs(TransportOutputType.SYNC).next;

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeOptionsBox --> this;
        this.nodeInputsBox --> this;
        this.nodeOutputsModifierBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();

        // Shreds
        spork ~ this.processOptions() @=> Shred @ processOptionsShred;
        spork ~ this.outputBeat() @=> Shred @ outputBeatShred;
        spork ~ this.outputClock() @=> Shred @ outputClockShred;
        spork ~ this.processExternalClockSync() @=> Shred @ processExternalClockSyncShred;
        this.addShreds([processOptionsShred, outputBeatShred, outputClockShred, processExternalClockSyncShred]);
    }

    fun float updateSync() {
        return ((60. / this.tempo) / this.beatDiv);
    }

    fun dur beatDur() {
        return ((30. / this.tempo) / this.beatDiv)::second;
    }

    fun dur pulseDur() {
        return (30.0 / (this.tempo * this.PPQN))::second;
    }

    fun void outputBeat() {
        while (this.nodeActive) {
            0.5 => this.nodeOutputsBox.outs(TransportOutputType.BEAT).next;
            this.beatDur() => now;

            0.0 => this.nodeOutputsBox.outs(TransportOutputType.BEAT).next;
            this.beatDur() => now;
        }
    }

    fun void outputClock() {
        while (this.nodeActive) {
            0.5 => this.nodeOutputsBox.outs(TransportOutputType.CLOCK).next;
            this.pulseDur() => now;

            0.0 => this.nodeOutputsBox.outs(TransportOutputType.CLOCK).next;
            this.pulseDur() => now;
        }
    }

    fun void processExternalClockSync() {
        while (this.nodeActive) {
            // Wait until an external clock is connected
            this.syncToExternalClock => now;

            // Circular buffer for pulse periods (size = 2 * PPQN)
            this.PPQN * 2 => int bufSize;
            float pulseTimes[bufSize];
            0 => int bufferIdx;
            0 => int bufferCount;

            0 => int wasHigh;
            0 => int hasPrevRise;
            time riseTime;

            while (this.externalClockConnected) {
                if (this.externalClock == null) break;

                this.getValueFromUGen(this.externalClock) => float val;
                if (!wasHigh && val >= this.threshold) {
                    // Rising edge — measure period from previous rise
                    if (hasPrevRise) {
                        (now - riseTime) / 1::second => float period;
                        period => pulseTimes[bufferIdx];
                        (bufferIdx + 1) % bufSize => bufferIdx;
                        Math.min(bufferCount + 1, bufSize) => bufferCount;

                        // Update tempo once we have at least PPQN measurements
                        if (bufferCount >= this.PPQN) {
                            0. => float sumTime;
                            for (int i; i < this.PPQN; i++) {
                                (bufferIdx - 1 - i + bufSize) % bufSize => int idx;
                                pulseTimes[idx] +=> sumTime;
                            }
                            sumTime / this.PPQN => float avgPeriod;

                            // period = 60 / (tempo * PPQN)  →  tempo = 60 / (PPQN * period)
                            Math.round(60.0 / (this.PPQN * avgPeriod)) => this.tempo;
                            (this.nodeOptionsBox$TransportOptionsBox).tempoEntryBox.set(Std.ftoi(this.tempo));
                            this.updateSync() => this.nodeOutputsBox.outs(TransportOutputType.SYNC).next;
                        }
                    }
                    now => riseTime;
                    1 => hasPrevRise;
                    1 => wasHigh;
                } else if (wasHigh && val < this.threshold) {
                    // Falling edge — update state only, timing is rise-to-rise
                    0 => wasHigh;
                }

                1::samp => now;
            }
        }
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        // Check if connecting an external clock
        if (dataType == TransportInputType.CLOCK.id) {
            1 => this.externalClockConnected;
            ugen @=> this.externalClock;
            this.syncToExternalClock.signal();
        }
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        // Check if disconnecting an external clock
        if (dataType == TransportInputType.CLOCK.id) {
            0 => this.externalClockConnected;
            null @=> this.externalClock;
        }
    }

    fun void processOptions() {
        this.nodeOptionsBox$TransportOptionsBox @=> TransportOptionsBox optionsBox;

        while (this.nodeActive) {
            optionsBox.updateNumberEntryBoxEvent => now;

            optionsBox.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx ;
            optionsBox.updateNumberEntryBoxEvent.numberBoxFloatValue => float numberBoxFloatValue ;

            if (numberBoxIdx == 0) {
                numberBoxFloatValue => this.tempo;
            } else if (numberBoxIdx == 1) {
                numberBoxFloatValue => this.beatDiv;
            } else if (numberBoxIdx == 2) {
                numberBoxFloatValue$int => this.PPQN;
            } else if (numberBoxIdx == 3) {
                numberBoxFloatValue => this.threshold;
            }

            this.updateSync() => this.nodeOutputsBox.outs(TransportOutputType.SYNC).next;
        }
    }

    fun HashMap serialize() {
        super.serialize() @=> HashMap data;

        // Option data
        data.set("tempo", this.tempo);
        data.set("beatDiv", this.beatDiv);
        data.set("PPQN", this.PPQN);
        data.set("threshold", this.threshold);

        // Get output data
        HashMap outputMenuData;
        for (int idx; idx < this.nodeOutputsBox.menus.size(); idx++) {
            // Menu data
            this.nodeOutputsBox.menus[idx] @=> DropdownMenu menu;
            outputMenuData.set(idx, menu.getSelectedEntry().id);
        }
        data.set("outputMenuData", outputMenuData);

        return data;
    }
}
