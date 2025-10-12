@import "../utils.ck"
@import {"../sequencer/base.ck", "../sequencer/recorder.ck"}
@import "base.ck"
@import "HashMap"
@import "smuck"


public class SequencerInputType {
    new Enum(0, "Run") @=> static Enum RUN;
    new Enum(1, "Record") @=> static Enum RECORD;

    [
        SequencerInputType.RUN,
        SequencerInputType.RECORD,
    ] @=> static Enum allTypes[];
}


public class SequencerOutputType {
    new Enum(0, "Seq Out") @=> static Enum SEQ_OUT;

    [
        SequencerOutputType.SEQ_OUT,
    ] @=> static Enum allTypes[];
}


public class SequencerNode extends Node {
    MidiRecorder recorder;
    Sequence sequences[0];

    // Run mode
    int _run;

    fun @construct() {
        SequencerNode(1, 4.);
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

    fun int isRunning() {
        return this._run;
    }

    fun void play() {
        // Turn sequencer on if not recording
        if (!this.recorder.isRecording()) 1 => this._run;
    }

    fun void stop() {
        0 => this._run;
    }

    fun void addJack(int ioType) {
         if (ioType == IOType.INPUT) {
            this.nodeInputsBox.addJack(SequencerInputType.allTypes);
        }
        this.updatePos();
    }

    fun void removeJack(int ioType) {
        if (ioType == IOType.INPUT) {
            this.nodeInputsBox.removeJack();
        }
        this.updatePos();
    }

    fun void processInputs() {
        while (this.nodeActive) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                if (this.nodeInputsBox.getDataTypeMapping(idx) == -1) continue;

                // Value can be from a audio rate UGen (which uses last()) or a control rate UGen (which uses next())
                this.nodeInputsBox.jacks[idx].ugen @=> UGen ugen;
                if (ugen == null) continue;

                float value;
                if (Type.of(ugen).name() == Step.typeOf().name()) {
                    (ugen$Step).next() => value;
                } else {
                    ugen.last() => value;
                }

                // Start playback of recorded Midi messages
                if (this.nodeInputsBox.getDataTypeMapping(idx) == SequencerInputType.RUN.id) {
                    if (value > 0 && !this.isRunning()) {
                        this.play();
                        <<< "Start sequencer playback" >>>;
                    } else if  (value <= 0 && this.isRunning()) {
                        this.stop();
                        <<< "Stop sequencer playback" >>>;
                    }
                // Start recording messages from the connected Midi Node
                } else if (this.nodeInputsBox.getDataTypeMapping(idx) == SequencerInputType.RECORD.id) {
                    // Check if turning recording on and not already recording
                    if (value > 0 && !this.recorder.isRecording()) {
                        this.recorder.on();
                        <<< "Start recording" >>>;
                    // Check if turning recording off and is currently recording
                    } else if (value <= 0 && this.recorder.isRecording()) {
                        this.sequences << this.recorder.off();
                        <<< "End recording" >>>;
                    }
                }
            }
            10::ms => now;
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

        // Sequence data
        HashMap allSequenceData;
        for (int sequenceIdx; sequenceIdx < this.sequences.size(); sequenceIdx++) {
            this.sequences[sequenceIdx] @=> Sequence currSequence;
            currSequence.getRecords() @=> MidiRecord records[];

            HashMap sequenceData;
            for (int recordIdx; recordIdx < records.size(); recordIdx++) {
                records[recordIdx] @=> MidiRecord record;

                HashMap recordData;
                recordData.set("data1", record.data1);
                recordData.set("data2", record.data2);
                recordData.set("data3", record.data3);
                recordData.set("timeSinceLast", record.timeSinceLast / 1::samp);

                sequenceData.set(recordIdx, recordData);
            }

            allSequenceData.set(sequenceIdx, sequenceData);
        }
        data.set("sequenceData", allSequenceData);

        return data;
    }
}
