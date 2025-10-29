/*

    Focus on MidiIn
        - Select a Channel
        - Pitch
        - Gate
        - Polyphonic Aftertouch
        - Control Change

*/

// Imports
@import "../tuning/base.ck"
@import "../utils.ck"
@import "../sequencer/recorder.ck"
@import "../ui/menu.ck"
@import "../events.ck"
@import {"base.ck", "sequencer.ck", "tuning.ck"}
@import "HashMap"


public class MidiConstants {
    -1 => static int ALL_CHANNELS;
    16 => static int NUM_CHANNELS;
}


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

    [
        0, 0, 0, 0, 0, 1,
    ] @=> static int includeNumberEntry[];
}


public class MidiInputType {
    new Enum(0, "Sequencer") @=> static Enum SEQUENCER;
    new Enum(1, "Latch") @=> static Enum LATCH;
    new Enum(2, "Transport") @=> static Enum TRANSPORT;
    new Enum(3, "Tuning") @=> static Enum TUNING;

    [
        MidiInputType.SEQUENCER,
        MidiInputType.LATCH,
        MidiInputType.TRANSPORT,
        MidiInputType.TUNING,
    ] @=> static Enum allTypes[];
}


public class SynthMode {
    new Enum(0, "Mono") @=> static Enum MONO;
    new Enum(1, "Arp") @=> static Enum ARP;
    new Enum(2, "Poly") @=> static Enum POLY;

    [
        SynthMode.MONO,
        SynthMode.ARP,
        SynthMode.POLY,
    ] @=> static Enum allModes[];
}


public class PlaybackMode {
    0 => static int INSTRUMENT_MODE;
    1 => static int SEQUENCE_MODE;
}


public class MidiOptionsBox extends OptionsBox {
    DropdownMenu @ channelSelectMenu;
    DropdownMenu @ synthModeSelectMenu;
    DropdownMenu @ latchSelectMenu;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Channel Menu
        Enum channelMenuItems[0];
        channelMenuItems << new Enum(-1, "All");
        for (int idx; idx < MidiConstants.NUM_CHANNELS; idx++) {
            channelMenuItems << new Enum(idx, Std.itoa(idx + 1));
        }

        // Midi Channel Select Menu
        new DropdownMenu(channelMenuItems) @=> this.channelSelectMenu;
        this.channelSelectMenu.updateSelectedEntry(0);

        // Synth Mode Select Menu
        new DropdownMenu(SynthMode.allModes) @=> this.synthModeSelectMenu;
        this.synthModeSelectMenu.updateSelectedEntry(0);

        // Latch Select Menu
        new DropdownMenu([new Enum(0, "Off"), new Enum(1, "On")]) @=> this.latchSelectMenu;
        this.latchSelectMenu.updateSelectedEntry(0);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.channelSelectMenu.pos;
        @(0.75, this.optionNames[1].posY(), 0.201) => this.synthModeSelectMenu.pos;
        @(0.75, this.optionNames[2].posY(), 0.201) => this.latchSelectMenu.pos;

        // Name
        "ChannelSelectMenu Dropdown Menu" => this.channelSelectMenu.name;
        "SynthModeSelectMenu Dropdown Menu" => this.synthModeSelectMenu.name;
        "LatchSelectMenu Dropdown Menu" => this.latchSelectMenu.name;
        "Midi Options Box" => this.name;

        // Connections
        this.channelSelectMenu --> this;
        this.synthModeSelectMenu --> this;
        this.latchSelectMenu --> this;
    }

    fun int mouseOverMenuEntry(vec3 mouseWorldPos, Node parentNode, DropdownMenu menu) {
        if (!menu.expanded) return -1;

        -1 => int menuEntryIdx;
        for (int idx; idx < menu.menuItemBoxes.size(); idx++) {
            menu.menuItemBoxes[idx] @=> BorderedBox entryBox;
            if (parentNode.mouseOverBox(mouseWorldPos, [this, menu, entryBox, entryBox.box])) {
                idx => menuEntryIdx;
                break;
            }
        }

        return menuEntryIdx;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        if (this.channelSelectMenu.expanded) {
            this.parent()$Node @=> Node parentNode;
            this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.channelSelectMenu) => int hoveredMenuEntryIdx;
            this.channelSelectMenu.highlightHoveredEntry(hoveredMenuEntryIdx);
        }

        if (this.synthModeSelectMenu.expanded) {
            this.parent()$Node @=> Node parentNode;
            this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.synthModeSelectMenu) => int hoveredMenuEntryIdx;
            this.synthModeSelectMenu.highlightHoveredEntry(hoveredMenuEntryIdx);
        }

        if (this.latchSelectMenu.expanded) {
            this.parent()$Node @=> Node parentNode;
            this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.latchSelectMenu) => int hoveredMenuEntryIdx;
            this.latchSelectMenu.highlightHoveredEntry(hoveredMenuEntryIdx);
        }
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        Type.of(this.parent()).name() => string parentName;

        // MidiIn Nodes
        if (parentName == MidiInNode.typeOf().name()) {
            this.parent()$MidiInNode @=> MidiInNode parentNode;

            // Check if channel menu is open and clicking on an option
            -1 => int channelMenuEntryIdx;
            if (this.channelSelectMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.channelSelectMenu) => channelMenuEntryIdx;

                if (channelMenuEntryIdx != -1) {
                    this.channelSelectMenu.updateSelectedEntry(channelMenuEntryIdx);
                    this.channelSelectMenu.getSelectedEntry() @=> Enum selectedChannel;
                    selectedChannel.id => parentNode.setChannel;
                    this.channelSelectMenu.collapse();
                    0 => this.menuOpen;
                    return true;
                }
            }

            // Check if clicking on channel menu && other menus are closed
            if (!this.synthModeSelectMenu.expanded && !this.latchSelectMenu.expanded && parentNode.mouseOverBox(mouseWorldPos, [this, this.channelSelectMenu, this.channelSelectMenu.selectedBox.box])) {
                if (!this.channelSelectMenu.expanded) {
                    this.channelSelectMenu.expand();
                    1 => this.menuOpen;
                    return true;
                }
            } else {
                this.channelSelectMenu.collapse();
            }

            // Check if mode menu is open and clicking on an option
            -1 => int synthModeMenuEntryIdx;
            if (this.synthModeSelectMenu.expanded && channelMenuEntryIdx == -1) {
                this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.synthModeSelectMenu) => synthModeMenuEntryIdx;

                if (synthModeMenuEntryIdx != -1) {
                    this.synthModeSelectMenu.updateSelectedEntry(synthModeMenuEntryIdx);
                    this.synthModeSelectMenu.getSelectedEntry() @=> Enum selectedMode;
                    selectedMode.id => parentNode.synthMode;
                    this.synthModeSelectMenu.collapse();
                    0 => this.menuOpen;
                    return true;
                }
            }

            // Check if clicking on mode menu && other menus are closed
            if (channelMenuEntryIdx == -1 && !this.channelSelectMenu.expanded && !this.latchSelectMenu.expanded && parentNode.mouseOverBox(mouseWorldPos, [this, this.synthModeSelectMenu, this.synthModeSelectMenu.selectedBox.box])) {
                if (!this.synthModeSelectMenu.expanded) {
                    this.synthModeSelectMenu.expand();
                    1 => this.menuOpen;
                    return true;
                }
            } else {
                this.synthModeSelectMenu.collapse();
            }

            -1 => int latchMenuEntryIdx;
            if (this.latchSelectMenu.expanded && channelMenuEntryIdx == -1 && synthModeMenuEntryIdx == -1) {
                this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.latchSelectMenu) => latchMenuEntryIdx;

                if (latchMenuEntryIdx != -1) {
                    this.latchSelectMenu.updateSelectedEntry(latchMenuEntryIdx);
                    this.latchSelectMenu.getSelectedEntry() @=> Enum selectedLatch;
                    selectedLatch.id => parentNode.latch;
                    this.latchSelectMenu.collapse();
                    0 => this.menuOpen;
                    return true;
                }
            }

            // Check if clicking on latch menu && other menus are closed
            if (latchMenuEntryIdx == -1 && !this.channelSelectMenu.expanded && !this.synthModeSelectMenu.expanded && parentNode.mouseOverBox(mouseWorldPos, [this, this.latchSelectMenu, this.latchSelectMenu.selectedBox.box])) {
                if (!this.latchSelectMenu.expanded) {
                    this.latchSelectMenu.expand();
                    1 => this.menuOpen;
                    return true;
                }
            } else {
                this.synthModeSelectMenu.collapse();
            }


            // Check if no menus are open
            if (!this.channelSelectMenu.expanded
                && !this.synthModeSelectMenu.expanded
                && !this.latchSelectMenu.expanded)
            {
                0 => this.menuOpen;
            }
        }

        return false;
    }
}


public class MidiNode extends Node {
    int channel;
    string ioType;

    fun @construct(int channel, string name, int type) {
        MidiNode(channel, name, type, 4.);
    }

    fun @construct(int channel, string name, int type, float xScale) {
        // Member variables
        channel => this.channel;
        IOType.toString(type) => this.ioType;

        // Create name box
        new NameBox(name + " " + this.ioType, xScale) @=> this.nodeNameBox;

        // Create options box with this node's scale
        new MidiOptionsBox(["Channel", "Mode", "Latch"], xScale) @=> this.nodeOptionsBox;

        // Create visibility box with this node's scale
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Names
        name + " " + this.ioType + " Channel " + this.channel => this.name;

        // Set ID
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Connections
        this.nodeNameBox --> this;
        this.nodeOptionsBox --> this;
        this.nodeVisibilityBox --> this;
    }

    fun void setChannel(int channel) {
        // -1 is "ALL" channels
        if (channel < MidiConstants.ALL_CHANNELS || channel >= MidiConstants.NUM_CHANNELS) return;

        channel => this.channel;
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

    // Playback mode
    int _playbackMode;

    // Latch
    int _latch;

    // Beat
    float _beat;

    // Data handling
    int midiDataTypeToOut[0];

    // Sequencing
    SequencerNode @ sequencer;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;

    fun @construct(string deviceName, int channel, int numInputs, int numOutputs) {
        MidiInNode(deviceName, channel, numInputs, numOutputs, 4.);
    }

    fun @construct(string deviceName, int channel, int numInputs, int numStartJacks, float xScale) {
        // Attempt to connect
        if ( !this.m.open(deviceName) ) {
            <<< "Unable to connect to MIDI In device with name:", deviceName >>>;
            return;
        }

        // Set Default tuning
        new EDO(12, -48) @=> this.tuning;

        // Set default beat
        (60 / 120.) => this.beat;

        // Create Inputs IO box
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(numInputs, MidiInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;

        // Create Outputs IO box
        new IOModifierBox(xScale) @=> this.nodeOutputsModifierBox;
        new IOBox(numStartJacks, MidiDataType.allTypes, MidiDataType.includeNumberEntry, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.setNumberBoxUpdateEvent(this.updateNumberEntryBoxEvent);

        // Parent class constructor
        MidiNode(channel, this.m.name(), IOType.INPUT, xScale);

        // Connect IO box to node
        this.nodeInputsModifierBox --> this;
        this.nodeInputsBox --> this;
        this.nodeOutputsModifierBox --> this;
        this.nodeOutputsBox --> this;

        // Update all box positions
        // Must be done after all boxes are connected to the node
        this.updatePos();

        // Shreds
        spork ~ this.processMidi() @=> Shred @ processMidiShred;
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        spork ~ this.processNumberBoxUpdates() @=> Shred @ processNumberBoxShred;
        this.addShreds([processMidiShred, processInputsShred, processNumberBoxShred]);
    }

    fun void synthMode(int mode) {
        mode => this._synthMode;
    }

    fun int synthMode() {
        return this._synthMode;
    }

    fun void playbackMode(int mode) {
        mode => this._playbackMode;
    }

    fun int playbackMode() {
        return this._playbackMode;
    }

    fun void latch(int latchSetting) {
        latchSetting => this._latch;

        // if latch is turned off, and there are no held notes, turn off gate
        if (latchSetting == 0 && this.heldNotes.size() == 0) {
            this.outputDataTypeIdx(MidiDataType.GATE, 0) => int gateOutIdx;
            if (gateOutIdx != -1) 0. => this.nodeOutputsBox.outs[gateOutIdx].next;
        }
    }

    fun int latch() {
        return this._latch;
    }

    fun void beat(float b) {
        b => this._beat;
    }

    fun float beat() {
        return this._beat;
    }

    fun void outputDataTypeIdx(Enum midiDataType, int voiceIdx, int outIdx) {
        // Update midi data type to output idx
        Std.itoa(midiDataType.id) + Std.itoa(voiceIdx) => string key;
        outIdx => this.midiDataTypeToOut[key];

        // Add Step output to Jack
        this.nodeOutputsBox.jacks[outIdx].setUgen(this.nodeOutputsBox.outs[outIdx]);
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

    fun void removeOutputDataTypeMappingByOutIdx(Enum midiDataType, int outIdx) {
        for (int idx; idx < this.midiDataTypeToOut.size(); idx++) {
            Std.itoa(midiDataType.id) + Std.itoa(idx) => string key;
            if (this.midiDataTypeToOut.isInMap(key) && this.midiDataTypeToOut[key] == outIdx) {
                this.midiDataTypeToOut.erase(key);
                break;
            }
        }
    }

    fun void addJack(int ioType) {
        if (ioType == IOType.OUTPUT) {
            this.nodeOutputsBox.addJack(MidiDataType.allTypes);

            // Update new menu with Event
            this.nodeOutputsBox.numberBoxes[-1].setUpdateEvent(this.updateNumberEntryBoxEvent);

        } else if (ioType == IOType.INPUT) {
            this.nodeInputsBox.addJack(MidiInputType.allTypes);
        }
        this.updatePos();
    }

    fun void removeJack(int ioType) {
        if (ioType == IOType.OUTPUT) {
            this.nodeOutputsBox.removeJack() @=> Enum removedMenuSelection;

            // Remove OutputDataType mapping
            this.removeOutputDataTypeMapping(removedMenuSelection, 0);
        } else if (ioType == IOType.INPUT) {
            this.nodeInputsBox.removeJack() @=> Enum removedMenuSelection;
        }
        this.updatePos();

    }

    fun void sendTrigger(int triggerOutIdx) {
        // Send a short trigger signal
        1. => this.nodeOutputsBox.outs[triggerOutIdx].next;
        5::ms => now;
        0. => this.nodeOutputsBox.outs[triggerOutIdx].next;
    }

    fun void clear() {
        this.heldNotes.reset();
        this.outputDataTypeIdx(MidiDataType.GATE, 0) => int gateOutIdx;
        if (gateOutIdx != -1) 0. => this.nodeOutputsBox.outs[gateOutIdx].next;
    }

    fun void arpeggiate() {
        while (this.heldNotes.size()) {
            0 => int idx;
            for (int idx; idx < this.heldNotes.size(); idx++) {
                this.heldNotes[idx] => int note;
                this.outputDataTypeIdx(MidiDataType.PITCH, 0) => int pitchOutIdx;
                if (pitchOutIdx != -1) this.tuning.cv(note) => this.nodeOutputsBox.outs[pitchOutIdx].next;
                this.beat()::second => now;
            }
        }
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == MidiInputType.SEQUENCER.id) {
            if (Type.of(outputNode).name() == SequencerNode.typeOf().name()) {
                <<< "CONNECTING A SEQUENCER" >>>;
                outputNode$SequencerNode @=> this.sequencer;
            }
        } else if (dataType == MidiInputType.TUNING.id) {
            if (Type.of(outputNode).name() == ScaleTuningNode.typeOf().name()) {
                <<< "Connecting a Tuning File Node" >>>;
                // outputNode$TuningFileNode
                (outputNode$ScaleTuningNode).tuning @=> this.tuning;
            } else if (Type.of(outputNode).name() == EDOTuningNode.typeOf().name()) {
                <<< "Connecting an EDO Tuning Node" >>>;
                (outputNode$EDOTuningNode).tuning @=> this.tuning;
            }
        }
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        // Remove dataType mapping
        this.nodeInputsBox.removeDataTypeMapping(inputJackIdx);

        // Remove any additional mappings
        if (dataType == MidiInputType.SEQUENCER.id) {
            null => this.sequencer;
        } else if (dataType == dataType == MidiInputType.TUNING.id) {
            new EDO(12, -48) @=> this.tuning;
        }
    }

    fun void processInputs() {
        while (this.nodeActive) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                // Check if DataType is set in a Menu
                this.nodeInputsBox.getDataTypeMapping(idx) => int dataType;
                if (dataType == -1) continue;

                // Inputs that don't use "UGen", just the Node
                if (dataType == MidiInputType.SEQUENCER.id) {
                    if (this.sequencer != null) {
                        if (this.sequencer.isRunning() && this.playbackMode() != PlaybackMode.SEQUENCE_MODE) {
                            PlaybackMode.SEQUENCE_MODE => this.playbackMode;
                            spork ~ this.playSequence();
                        } else if (!this.sequencer.isRunning()) {
                            PlaybackMode.INSTRUMENT_MODE => this.playbackMode;
                        }
                    }
                }

                // Get UGen
                this.nodeInputsBox.jacks[idx].ugen @=> UGen ugen;
                if (ugen == null) continue;

                // UGen can either be Audio Rate (which uses last()) or Control Rate (which uses next())
                float value;
                if (Type.of(ugen).name() == Step.typeOf().name()) {
                    (ugen$Step).next() => value;
                } else {
                    ugen.last() => value;
                }

                // Update based on inputs that use a UGen
                if (dataType == MidiInputType.LATCH.id) {
                    if (value <= 0) 0 => this.latch;
                    else 1 => this.latch;
                } else if (dataType == MidiInputType.TRANSPORT.id) {
                    value => this.beat;
                }
            }
            10::ms => now;
        }
    }

    fun void processNumberBoxUpdates() {
        while (this.nodeActive) {
            this.updateNumberEntryBoxEvent => now;

            this.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx;
            this.updateNumberEntryBoxEvent.numberBoxValue => int numberBoxValue;

            // Get menu associated with number box
            this.nodeOutputsBox.menus[numberBoxIdx] @=> DropdownMenu menu;
            menu.getSelectedEntry() @=> Enum selectedEntry;

            // Remove old mapping
            this.removeOutputDataTypeMappingByOutIdx(selectedEntry, numberBoxIdx);

            // Update output data type mapping
            <<< "Updating output data type mapping ", selectedEntry.name, numberBoxValue, numberBoxIdx >>>;
            this.outputDataTypeIdx(selectedEntry, numberBoxValue, numberBoxIdx);
        }
    }

    fun void playSequence() {
        if (this.sequencer == null) return;

        MidiMsg msg;
        for (int idx; idx < this.sequencer.sequences.size(); idx++) {
            this.sequencer.sequences[idx] @=> Sequence sequence;

            // Check if we are still sequencing
            if (this.playbackMode() != PlaybackMode.SEQUENCE_MODE) return;

            for (MidiRecord record : sequence.getRecords()) {
                record.timeSinceLast => now;
                record.data1 => msg.data1;
                record.data2 => msg.data2;
                record.data3 => msg.data3;

                this.processMidiMsg(msg);
                if (!this.sequencer.isRunning()) {
                    this.clear();
                    return;
                }
            }
        }
    }

    fun void processMidi() {
        while (this.nodeActive) {
            // Check if in sequence mode, then wait
            if (this.playbackMode() != PlaybackMode.INSTRUMENT_MODE) {
                10::ms => now;
                continue;
            }

            // Wait for Midi event
            this.m => now;

            // Process Midi event
            while (this.m.recv(this.msg)) {
                this.processMidiMsg(this.msg) => int midiProcessed;

                // Check if recording in progress, and record incoming MidiMsg
                if (midiProcessed && this.sequencer != null && this.sequencer.recorder.isRecording()) this.sequencer.recorder.recordMsg(this.msg);
            }
        }
    }

    fun int checkMidiStatus(int midiStatus, int msgType, int channel) {
        // Check if MIDI Status corresponds to this Type (e.g. Note ON) and channel
        // If MIDI Channel is "All", check if Status is between msgType (e.g. Note ON) and the next boundary (e.g. Polyphonic aftertouch)
        if (midiStatus == msgType + channel || (channel == MidiConstants.ALL_CHANNELS && midiStatus >= msgType && midiStatus < msgType + MidiConstants.NUM_CHANNELS)) {
            return true;
        }

        return false;
    }

    fun int processMidiMsg(MidiMsg msg) {
        // Return status if MIDI message if processed by this channel
        0 => int midiProcessed;

        // Get message status
        msg.data1 => int midiStatus;

        // Note On
        if (this.checkMidiStatus(midiStatus, MidiMessage.NOTE_ON, this.channel)) {
            msg.data2 => int noteNumber;
            this.heldNotes << noteNumber;
            msg.data3 => int velocity;

            // Pitch out
            this.outputDataTypeIdx(MidiDataType.PITCH, 0) => int pitchOutIdx;
            if (pitchOutIdx != -1) {
                if (this.synthMode() == SynthMode.MONO.id) {
                    this.tuning.cv(noteNumber) => this.nodeOutputsBox.outs[pitchOutIdx].next;
                } else if (this.synthMode() == SynthMode.ARP.id) {
                    if (this.heldNotes.size() == 1) spork ~ this.arpeggiate();
                }
            }

            // Gate out
            this.outputDataTypeIdx(MidiDataType.GATE, 0) => int gateOutIdx;
            if (gateOutIdx != -1) 1. => this.nodeOutputsBox.outs[gateOutIdx].next;

            // Trigger out
            this.outputDataTypeIdx(MidiDataType.TRIGGER, 0) => int triggerOutIdx;
            if (triggerOutIdx != -1) spork ~ this.sendTrigger(triggerOutIdx);

            // Velocity out
            this.outputDataTypeIdx(MidiDataType.VELOCITY, 0) => int velocityOutIdx;
            if (velocityOutIdx != -1) Std.scalef(velocity, 0, 127, 0., 0.5) => this.nodeOutputsBox.outs[velocityOutIdx].next;

            // Set processed status
            1 => midiProcessed;
        // Note off
        } else if (this.checkMidiStatus(midiStatus, MidiMessage.NOTE_OFF, this.channel)) {
            msg.data2 => int noteNumber;
            msg.data3 => int velocity;

            // Remove note from held notes
            for (this.heldNotes.size() - 1 => int idx; idx >= 0; idx-- ) {
                if (this.heldNotes[idx] == noteNumber) {
                    this.heldNotes.popOut(idx);
                    break;
                }
            }

            // Turn off gate if no held notes
            if (this.heldNotes.size() == 0) {
                // Only turn off gate if latch is off
                if (this.latch() == 0) {
                    // Turn off gate
                    this.outputDataTypeIdx(MidiDataType.GATE, 0) => int gateOutIdx;
                    if (gateOutIdx != -1) 0. => this.nodeOutputsBox.outs[gateOutIdx].next;

                    // Turn off aftertouch
                    this.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0) => int aftertouchOutIdx;
                    if (aftertouchOutIdx != -1) 0. => this.nodeOutputsBox.outs[aftertouchOutIdx].next;

                    // Turn off velocity
                    this.outputDataTypeIdx(MidiDataType.VELOCITY, 0) => int velocityOutIdx;
                    if (velocityOutIdx != -1) 0. => this.nodeOutputsBox.outs[velocityOutIdx].next;
                }

            // Otherwise go back to previously held note
            } else {
                this.outputDataTypeIdx(MidiDataType.PITCH, 0) => int pitchOutIdx;
                if (pitchOutIdx != -1 && this.synthMode() == SynthMode.MONO.id) this.tuning.cv(this.heldNotes[-1]) => this.nodeOutputsBox.outs[pitchOutIdx].next;

                // Resend Trigger for previously held note
                this.outputDataTypeIdx(MidiDataType.TRIGGER, 0) => int triggerOutIdx;
                if (triggerOutIdx != -1) spork ~ this.sendTrigger(triggerOutIdx);
            }

            // Set processed status
            1 => midiProcessed;
        // Polyphonic aftertouch
        } else if (this.checkMidiStatus(midiStatus, MidiMessage.POLYPHONIC_AFTERTOUCH, this.channel)) {
            this.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0) => int aftertouchOutIdx;
            if (aftertouchOutIdx != -1 && msg.data2 == this.heldNotes[-1]) {
                Std.scalef(msg.data3, 0, 127, -0.5, 0.5) => this.nodeOutputsBox.outs[aftertouchOutIdx].next;
            }

            // Set processed status
            // 1 => midiProcessed;  // TODO: this is off right now so aftertouch values don't get recorded in sequences, at some point this should be changed
        // CC messages
        } else if (this.checkMidiStatus(midiStatus, MidiMessage.CONTROL_CHANGE, this.channel)) {
            msg.data2 => int controllerNumber;
            msg.data3 => int controllerData;

            this.outputDataTypeIdx(MidiDataType.CC, controllerNumber) => int ccOutIdx;
            if (ccOutIdx != -1) Std.scalef(controllerData, 0, 127, -0.5, 0.5) => this.nodeOutputsBox.outs[ccOutIdx].next;

            // Set processed status
            // 1 => midiProcessed;
        }

        return midiProcessed;
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        // Midi Data
        data.set("channel", this.channel);
        data.set("synthMode", this.synthMode());
        data.set("latch", this.latch());
        data.set("midiName", this.m.name());
        data.set("midiID", this.m.num());
        data.set("optionsActive", this.nodeOptionsBox.active);
        data.set("inputsActive", this.nodeInputsBox.active);
        data.set("outputsActive", this.nodeOutputsBox.active);
        data.set("numInputs", this.nodeInputsBox.numJacks);
        data.set("numOutputs", this.nodeOutputsBox.numJacks);

        // Get input menu data
        HashMap inputMenuData;
        for (int idx; idx < this.nodeInputsBox.menus.size(); idx++) {
            this.nodeInputsBox.menus[idx] @=> DropdownMenu menu;
            inputMenuData.set(idx, menu.getSelectedEntry().id);
        }
        data.set("inputMenuData", inputMenuData);

        // Get output menu and numberBox data
        HashMap outputMenuData;
        HashMap outputNumberBoxData;
        for (int idx; idx < this.nodeOutputsBox.menus.size(); idx++) {
            // Menu data
            this.nodeOutputsBox.menus[idx] @=> DropdownMenu menu;
            outputMenuData.set(idx, menu.getSelectedEntry().id);

            // NUmberBox data
            this.nodeOutputsBox.numberBoxes[idx] @=> NumberEntryBox numberBox;
            outputNumberBoxData.set(idx, numberBox.getInt());

        }
        data.set("outputMenuData", outputMenuData);
        data.set("outputNumberBoxData", outputNumberBoxData);

        return data;
    }
}
