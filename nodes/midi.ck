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


public class MidiOptionsBox extends OptionsBox {
    DropdownMenu @ channelSelectMenu;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Channel Menu
        Enum channelMenuItems[0];
        channelMenuItems << new Enum(-1, "All");
        for (int idx; idx < 16; idx++) {
            channelMenuItems << new Enum(idx, Std.itoa(idx + 1));
        }

        new DropdownMenu(channelMenuItems) @=> this.channelSelectMenu;
        this.channelSelectMenu.updateSelectedEntry(0);

        // Position
        @(0.75, 0., 0.201) => this.channelSelectMenu.pos;

        // Name
        "ChannelSelectMenu Dropdown Menu" => this.channelSelectMenu.name;
        "Midi Options Box" => this.name;

        // Connections
        this.channelSelectMenu --> this;
    }

    fun void updatePos() {
        for (int idx; idx < this.optionNames.size(); idx++) {
            Math.fabs(this.contentBox.posY()) - idx => this.optionNames[idx].posY;
        }

        this.optionNames[0].posY() => this.channelSelectMenu.posY;
    }

    fun int mouseOverMenuEntry(vec3 mouseWorldPos, Node parentNode, DropdownMenu menu) {
        if (!menu.expanded) return -1;

        -1 => int menuEntryIdx;
        for (int idx; idx < this.channelSelectMenu.menuItemBoxes.size(); idx++) {
            this.channelSelectMenu.menuItemBoxes[idx] @=> BorderedBox entryBox;
            if (parentNode.mouseOverBox(mouseWorldPos, [this, this.channelSelectMenu, entryBox, entryBox.box])) {
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
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        false => int nodeOptionsBoxIteractedWith;

        Type.of(this.parent()).name() => string parentName;

        // MidiIn Nodes
        if (parentName == MidiInNode.typeOf().name()) {
            this.parent()$MidiInNode @=> MidiInNode parentNode;

            // Check if menu is open and clicking on an option
            if (this.channelSelectMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.channelSelectMenu) => int hoveredMenuEntryIdx;

                if (hoveredMenuEntryIdx != -1) {
                    this.channelSelectMenu.updateSelectedEntry(hoveredMenuEntryIdx);
                    this.channelSelectMenu.getSelectedEntry() @=> Enum selectedChannel;
                    selectedChannel.id => parentNode.setChannel;
                    true => nodeOptionsBoxIteractedWith;
                }
            }

            // Check if clicking on Channel menu options
            if (parentNode.mouseOverBox(mouseWorldPos, [this, this.channelSelectMenu, this.channelSelectMenu.selectedBox.box])) {
                if (!this.channelSelectMenu.expanded) {
                    this.channelSelectMenu.expand();
                    1 => this.menuOpen;
                    true => nodeOptionsBoxIteractedWith;
                }
            } else {
                this.channelSelectMenu.collapse();
                0 => this.menuOpen;
            }
        }

        return nodeOptionsBoxIteractedWith;
    }

    fun void handleNotClickedOn() {
        if (this.channelSelectMenu.expanded) {
            this.channelSelectMenu.collapse();
            0 => this.menuOpen;
        }
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
        new MidiOptionsBox(["Channel"], xScale) @=> this.nodeOptionsBox;

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
        if (channel < 0 || channel >= 16) return;

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

    // Data handling
    int midiDataTypeToOut[0];

    fun @construct(int deviceID, int channel, int numStartJacks) {
        MidiInNode(deviceID, channel, numStartJacks, 4.);
    }

    fun @construct(int deviceID, int channel, int numStartJacks, float xScale) {
        // Attempt to connect
        if ( !this.m.open(deviceID) ) {
            <<< "Unable to connect to MIDI In device with ID", deviceID >>>;
            return;
        }

        // Set Default tuning
        new EDO(12, -24) @=> this.tuning;

        // Create Outputs IO box
        new IOModifierBox(xScale) @=> this.nodeOutputsModifierBox;
        new IOBox(numStartJacks, MidiDataType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;

        // Parent class constructor
        MidiNode(channel, this.m.name(), IOType.INPUT, xScale);

        // Connect IO box to node
        this.nodeOutputsModifierBox --> this;
        this.nodeOutputsBox --> this;

        // Update all box positions
        // Must be done after all boxes are connected to the node
        this.updatePos();

        // Update NodeOptionsBox text positions
        // This has to happen after 1) all the boxes are scaled and 2) each box has its positions
        // because the text is part of the MidiOptionsBox object, NOT the MidiOptionsBox.box GCube object
        this.nodeOptionsBox.updatePos();
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

    fun void addJack() {
        this.nodeOutputsBox.addJack(MidiDataType.allTypes);
        this.updatePos();
    }

    fun void removeJack() {
        this.nodeOutputsBox.removeJack() @=> Enum removedMenuSelection;
        this.updatePos();

        // Remove OutputDataType mapping
        this.removeOutputDataTypeMapping(removedMenuSelection, 0);
    }

    fun void sendTrigger(int triggerOutIdx) {
        // Send a short trigger signal
        1. => this.nodeOutputsBox.outs[triggerOutIdx].next;
        5::ms => now;
        0. => this.nodeOutputsBox.outs[triggerOutIdx].next;
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
                        if (pitchOutIdx != -1) this.tuning.cv(noteNumber) => this.nodeOutputsBox.outs[pitchOutIdx].next;

                        // Gate out
                        this.outputDataTypeIdx(MidiDataType.GATE, 0) => int gateOutIdx;
                        if (gateOutIdx != -1) 1. => this.nodeOutputsBox.outs[gateOutIdx].next;

                        // Trigger out
                        this.outputDataTypeIdx(MidiDataType.TRIGGER, 0) => int triggerOutIdx;
                        if (triggerOutIdx != -1) spork ~ this.sendTrigger(triggerOutIdx);

                        // Velocity out
                        this.outputDataTypeIdx(MidiDataType.VELOCITY, 0) => int velocityOutIdx;
                        if (velocityOutIdx != -1) Std.scalef(velocity, 0, 127, 0., 0.5) => this.nodeOutputsBox.outs[velocityOutIdx].next;
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
                            if (gateOutIdx != -1) 0. => this.nodeOutputsBox.outs[gateOutIdx].next;

                            // Turn off aftertouch
                            this.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0) => int aftertouchOutIdx;
                            if (aftertouchOutIdx != -1) 0. => this.nodeOutputsBox.outs[aftertouchOutIdx].next;

                            // Turn off velocity
                            this.outputDataTypeIdx(MidiDataType.VELOCITY, 0) => int velocityOutIdx;
                            if (velocityOutIdx != -1) 0. => this.nodeOutputsBox.outs[velocityOutIdx].next;

                        // Otherwise go back to previously held note
                        } else {
                            this.outputDataTypeIdx(MidiDataType.PITCH, 0) => int pitchOutIdx;
                            if (pitchOutIdx != -1) this.tuning.cv(this.heldNotes[-1]) => this.nodeOutputsBox.outs[pitchOutIdx].next;

                            // Resend Trigger for previously held note
                            this.outputDataTypeIdx(MidiDataType.TRIGGER, 0) => int triggerOutIdx;
                            if (triggerOutIdx != -1) spork ~ this.sendTrigger(triggerOutIdx);
                        }

                    // Polyphonic aftertouch
                    } else if (midiStatus == MidiMessage.POLYPHONIC_AFTERTOUCH + this.channel) {
                        this.outputDataTypeIdx(MidiDataType.AFTERTOUCH, 0) => int aftertouchOutIdx;
                        if (aftertouchOutIdx != -1 && this.msg.data2 == this.heldNotes[-1]) {
                            Std.scalef(this.msg.data3, 0, 127, 0., 0.5) => this.nodeOutputsBox.outs[aftertouchOutIdx].next;
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
