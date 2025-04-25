/*

    Focus on MidiIn
        - Select a Channel
        - Pitch
        - Gate
        - Polyphonic Aftertouch
        - Control Change

*/

// Imports
@import "../tuning.ck"
@import "../utils.ck"
@import "../ui/menu.ck"
@import "base.ck"


public class MidiMessage {
    0x80 => static int NOTE_OFF;
    0x90 => static int NOTE_ON;
    0xA0 => static int POLYPHONIC_AFTERTOUCH;
    0xB0 => static int CONTROL_CHANGE;
    0xC0 => static int PROGRAM_CHANGE;
    0xD0 => static int CHANNEL_AFTERTOUCH;
    0xE0 => static int PITCH_WHEEL;
}


public class MidiDataType {
    new Enum(0, "Pitch") @=> static Enum PITCH;
    new Enum(1, "Gate") @=> static Enum GATE;
    new Enum(2, "Trigger") @=> static Enum TRIGGER;
    new Enum(3, "Velocity") @=> static Enum VELOCITY;
    new Enum(4, "Aftertouch") @=> static Enum AFTERTOUCH;
    new Enum(5, "CC") @=> static Enum CC;

    [
        MidiDataType.PITCH,
        MidiDataType.GATE,
        MidiDataType.TRIGGER,
        MidiDataType.VELOCITY,
        MidiDataType.AFTERTOUCH,
        MidiDataType.CC,
    ] @=> static Enum allTypes[];
}


public class SynthMode {
    0 => static int MONO;
    1 => static int ARP;
    2 => static int POLY;
}


public class MidiNode extends Node {
    int channel;
    string ioType;

    GText deviceName;

    fun @construct(int channel, string name, int type) {
        // Parent constructor
        Node();

        // Member variables
        channel => this.channel;
        ioType => this.ioType;

        // Content Box parameters
        1. => float yPos;
        if (this.numJacks > 0) this.numJacks => yPos;

        // Create jack modifier box with this node's scale
        new JackModifierBox(4.) @=> this.jackModifierBox;

        // Position
        @(0., 1., 0.101) => this.nodeName.pos;
        1. => this.nodeNameBox.posY;
        0.5 - (yPos / 2.) => this.nodeContentBox.posY;
        this.nodeContentBox.posY() - 2. => this.jackModifierBox.posY;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;
        @(0.25, 0.25, 0.25) => this.nodeName.sca;
        @(4., 1., 0.2) => this.nodeNameBox.sca;
        @(4., yPos, 0.2) => this.nodeContentBox.sca;

        // Text
        IOType.toString(type) => this.ioType;
        "Midi " + this.ioType => this.nodeName.text;
        name => this.deviceName.text;

        // Color
        @(3., 3., 3., 1.) => this.nodeName.color;
        Color.BLACK => this.nodeNameBox.color;
        Color.GRAY => this.nodeContentBox.color;

        // Names
        this.nodeName.text() + " " + name + " Channel " + this.channel => this.name;

        // Set ID
        Std.itoa(Math.random()) => string randomID;
        this.name() + " ID " + randomID => this.nodeID;

        // Connections
        this.nodeName --> this;
        this.nodeNameBox --> this;
        this.nodeContentBox --> this;
        this.jackModifierBox --> this;
    }
}


public class MidiInNode extends MidiNode {
    MidiIn m;
    MidiMsg msg;

    // Tuning
    Tuning @ tuning;

    // Note on/off
    int heldNotes[0];

    // Midi mode
    int _synthMode;

    // Data handling
    int midiDataTypeToOut[0];
    Step outs[0];

    fun @construct(int deviceID, int channel, int initJacks) {
        // Handle Jacks
        initJacks => this.numJacks;
        IOType.OUTPUT => int jackType;

        // Parent class constructor
        // Need to call this here to set nodeID
        MidiInNode(deviceID, channel);

        for (int idx; idx < initJacks; idx++) {
            Jack jack(idx, jackType);
            DropdownMenu jackMenu(MidiDataType.allTypes, this.nodeID, idx);
            Step out(0.);

            // Jack Position
            1.25 => jack.posX;
            idx * -1 => jack.posY;

            // Menu Position
            -0.75 => jackMenu.posX;
            idx * -1 => jackMenu.posY;
            0.1 => jackMenu.posZ;

            this.jacks << jack;
            this.menus << jackMenu;
            this.outs << out;

            // Jack Connection
            jack --> this;
            jackMenu --> this;
        }
    }

    fun @construct(int deviceID, int channel) {
        // Attempt to connect
        if ( !this.m.open(deviceID) ) {
            <<< "Unable to connect to MIDI In device with ID", deviceID >>>;
            return;
        }

        // Set Default tuning
        new EDO(12, -24) @=> this.tuning;

        // Parent class constructor
        MidiNode(channel, this.m.name(), IOType.INPUT);

    }

    fun void synthMode(int mode) {
        mode => this._synthMode;
    }

    fun int synthMode() {
        return this._synthMode;
    }

    fun void outputDataTypeIdx(Enum midiDataType, int voiceIdx, int outIdx) {
        // Update midi data type to output idx
        Std.itoa(midiDataType.id) + Std.itoa(voiceIdx) => string key;
        outIdx => this.midiDataTypeToOut[key];

        // Add Step output to Jack
        this.jacks[outIdx].setUgen(this.outs[outIdx]);
    }

    fun int outputDataTypeIdx(Enum midiDataType, int voiceIdx) {
        Std.itoa(midiDataType.id) + Std.itoa(voiceIdx) => string key;

        if (this.midiDataTypeToOut.isInMap(key)) {
            return this.midiDataTypeToOut[key];
        }

        return -1;
    }

    fun void removeOutputDataTypeMapping(Enum midiDataType, int voiceIdx) {
        Std.itoa(midiDataType.id) + Std.itoa(voiceIdx) => string key;
        this.midiDataTypeToOut.erase(key);
    }

    fun void sendTrigger(int triggerOutIdx) {
        // Send a short trigger signal
        1. => this.outs[triggerOutIdx].next;
        5::ms => now;
        0. => this.outs[triggerOutIdx].next;
    }

    fun void run() {
        while (true) {
            // Wait for Midi event
            this.m => now;

            // Process Midi event
            while (this.m.recv(this.msg)) {

                // Get message status
                this.msg.data1 => int midiStatus;

                // Mono Synth
                if (this.synthMode() == SynthMode.MONO) {
                    // Note On
                    if (midiStatus == MidiMessage.NOTE_ON + this.channel) {
                        this.msg.data2 => int noteNumber;
                        this.heldNotes << noteNumber;
                        this.msg.data3 => int velocity;

                        // Pitch out
                        this.outputDataTypeIdx(MidiDataType.PITCH, 0) => int pitchOutIdx;
                        if (pitchOutIdx != -1) this.tuning.cv(noteNumber) => this.outs[pitchOutIdx].next;

                        // Gate out
                        this.outputDataTypeIdx(MidiDataType.GATE, 0) => int gateOutIdx;
                        if (gateOutIdx != -1) 1. => this.outs[gateOutIdx].next;

                        // Trigger out
                        this.outputDataTypeIdx(MidiDataType.TRIGGER, 0) => int triggerOutIdx;
                        if (triggerOutIdx != -1) spork ~ this.sendTrigger(triggerOutIdx);

                        // Velocity out
                        this.outputDataTypeIdx(MidiDataType.VELOCITY, 0) => int velocityOutIdx;
                        if (velocityOutIdx != -1) Std.scalef(velocity, 0, 127, 0., 0.5) => this.outs[velocityOutIdx].next;
                    // Note off
                    } else if (midiStatus == MidiMessage.NOTE_OFF + this.channel) {
                        this.msg.data2 => int noteNumber;
                        this.msg.data3 => int velocity;

                        // Remove note from held notes
                        for (this.heldNotes.size() - 1 => int idx; idx >= 0; idx-- ) {
                            if (this.heldNotes[idx] == noteNumber) {
                                this.heldNotes.popOut(idx);
                                break;
                            }
                        }

                        // Turn off gate if no held notes
                        if (this.heldNotes.size() == 0) {
                            // Turn off gate
                            this.outputDataTypeIdx(MidiDataType.GATE, 0) => int gateOutIdx;
                            if (gateOutIdx != -1) 0. => this.outs[gateOutIdx].next;

                            // Turn off aftertouch
                            this.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0) => int aftertouchOutIdx;
                            if (aftertouchOutIdx != -1) 0. => this.outs[aftertouchOutIdx].next;

                            // Turn off velocity
                            this.outputDataTypeIdx(MidiDataType.VELOCITY, 0) => int velocityOutIdx;
                            if (velocityOutIdx != -1) 0. => this.outs[velocityOutIdx].next;

                        // Otherwise go back to previously held note
                        } else {
                            this.outputDataTypeIdx(MidiDataType.PITCH, 0) => int pitchOutIdx;
                            if (pitchOutIdx != -1) this.tuning.cv(this.heldNotes[-1]) => this.outs[pitchOutIdx].next;

                            // Resend Trigger for previously held note
                            this.outputDataTypeIdx(MidiDataType.TRIGGER, 0) => int triggerOutIdx;
                            if (triggerOutIdx != -1) spork ~ this.sendTrigger(triggerOutIdx);
                        }

                    // Polyphonic aftertouch
                    } else if (midiStatus == MidiMessage.POLYPHONIC_AFTERTOUCH + this.channel) {
                        this.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0) => int aftertouchOutIdx;
                        if (aftertouchOutIdx != -1 && this.msg.data2 == this.heldNotes[-1]) {
                            Std.scalef(this.msg.data3, 0, 127, 0., 0.5) => this.outs[aftertouchOutIdx].next;
                        }
                    }
                }

                // CC messages do not depend on synth mode
                if (midiStatus == MidiMessage.CONTROL_CHANGE + this.channel) {
                    this.msg.data2 => int controllerNumber;
                    this.msg.data3 => int controllerData;
                }
            }
        }
    }
}
