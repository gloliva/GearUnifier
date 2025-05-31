// Imports
@import "../saveHandler.ck"
@import "../events.ck"
@import "../ui/menu.ck"
@import "audio.ck"
@import "base.ck"
@import "midi.ck"
@import "sequencer.ck"
@import "transport.ck"
@import "effects/wavefolder.ck"
@import "utils/scale.ck"


public class NodeManager {
    // All Nodes
    Node nodesOnScreen[0];
    int numNodes;

    // All Connections
    Connection nodeConnections[0];
    Connection @ currOpenConnection;
    int openConnection;

    // Menus
    int menuOpen;
    DropdownMenu @ currMenu;

    // Number Entry Box
    int numberBoxSelected;
    int currNumberBoxIdx;
    NumberEntryBox @ currNumberBox;

    // Selected Node
    int nodeSelected;
    int currSelectedNodeIdx;
    Node @ currSelectedNode;

    // Held Node
    int nodeHeld;
    int currHeldNodeIdx;
    Node @ currHeldNode;

    // Selected Connection
    int connectionSelected;
    int currSelectedConnectionIdx;
    Connection @ currSelectedConnection;

    // Available Midi Devices
    Enum midiInDevices[0];
    Enum midiOutDevices[0];

    // Events
    MoveCameraEvent @ moveCameraEvent;

    fun @construct(MoveCameraEvent moveCameraEvent) {
        moveCameraEvent @=> this.moveCameraEvent;
    }

    fun void addNode(Node node) {
        this.nodesOnScreen << node;
        this.numNodes++;

        // Add to scene
        node --> GG.scene();
    }

    fun void removeNode(Node node) {
        -1 => int nodeIdx;
        for (int idx; idx < this.numNodes; idx++) {
            if (this.nodesOnScreen[idx].nodeID == node.nodeID) {
                idx => nodeIdx;
                break;
            }
        }

        // Check if there are connections from this node
        int connectionIdxs[0];
        for (int connIdx; connIdx < this.nodeConnections.size(); connIdx++) {
            this.nodeConnections[connIdx] @=> Connection conn;
            if (
                (conn.outputNode.nodeID == node.nodeID)
                || (conn.inputNode.nodeID == node.nodeID)
            ) {
                connectionIdxs << connIdx;
            }
        }

        // Remove any connections
        if (connectionIdxs.size() > 0) {
            // Start from the back
            connectionIdxs.reverse();

            // Remove each connection
            for (int connIdx : connectionIdxs) {
                this.nodeConnections[connIdx] @=> Connection conn;

                // Remove the connection UGen mapping
                conn.outputNode.nodeOutputsBox.jacks[conn.outputNodeJackIdx].ugen @=> UGen ugen;
                conn.inputNode.disconnect(conn.outputNode, ugen, conn.inputNodeJackIdx);
                conn.inputNode.nodeInputsBox.jacks[conn.inputNodeJackIdx].removeUgen();

                // Delete the wire
                conn.deleteWire();

                // Remove connection from connection list
                this.nodeConnections.erase(connIdx);
            }
        }

        // Remove node if in list
        if (nodeIdx != -1) {
            this.nodesOnScreen.popOut(nodeIdx);
            this.numNodes--;
        }

        // Exit node's shreds
        node.deactivateNode();

        // Remove from scene
        node --< GG.scene();
    }

    fun void addNodeHandler(AddNodeEvent addNodeEvent) {
        while (true) {
            addNodeEvent => now;
            if (addNodeEvent.nodeType == NodeType.MIDI_IN) {
                addNodeEvent.menuIdx => int midiDeviceID;
                MidiInNode midiIn(midiDeviceID, 0, 3);
                this.addNode(midiIn);
                spork ~ midiIn.processMidi() @=> Shred @ midiInProcessMidiShred;
                spork ~ midiIn.processInputs() @=> Shred @ midiInProcessInputsShred;
                spork ~ midiIn.processNumberBoxUpdates() @=> Shred @ midiInProcessNumberBoxShred;
                midiIn.addShreds([midiInProcessMidiShred, midiInProcessInputsShred, midiInProcessNumberBoxShred]);
            } else if (addNodeEvent.nodeType == NodeType.AUDIO_IN) {
                AudioInNode audioIn(adc.channels());
                this.addNode(audioIn);
            } else if (addNodeEvent.nodeType == NodeType.AUDIO_OUT) {
                AudioOutNode audioOut(dac.channels());
                this.addNode(audioOut);
            } else if (addNodeEvent.nodeType == NodeType.WAVEFOLDER) {
                WavefolderNode wavefolder();
                this.addNode(wavefolder);
                spork ~ wavefolder.processInputs() @=> Shred @ wavefolderProcessInputsShred;
                wavefolder.addShreds([wavefolderProcessInputsShred]);
            } else if (addNodeEvent.nodeType == NodeType.SEQUENCER) {
                SequencerNode sequencer();
                spork ~ sequencer.processInputs() @=> Shred @ sequencerProcessInputsShred;
                this.addNode(sequencer);
                sequencer.addShreds([sequencerProcessInputsShred]);
            } else if (addNodeEvent.nodeType == NodeType.TRANSPORT) {
                TransportNode transport();
                spork ~ transport.processOptions() @=> Shred @ transportProcessOptionsShred;
                this.addNode(transport);
                transport.addShreds([transportProcessOptionsShred]);
            } else if (addNodeEvent.nodeType == NodeType.SCALE) {
                ScaleNode scale();
                spork ~ scale.processOptions() @=> Shred @ scaleProcessOptionsShred;
                this.addNode(scale);
                scale.addShreds([scaleProcessOptionsShred]);
            }
        }
    }

    fun void saveHandler(UpdateTextEntryBoxEvent saveEvent) {
        while (true) {
            saveEvent => now;
            if (saveEvent.mode == SaveState.SAVE) {
                if (saveEvent.text.length() > 0) this.save(saveEvent.text);
            } else if (saveEvent.mode == SaveState.LOAD) {
                this.clearScreen();
                this.loadSave(saveEvent.text);
            }
        }
    }

    fun void findMidiDevices() {
        // Write `chuck --probe` output to file
        "chuck --probe 2>&1 | grep -A 10 \"MIDI\" > .midiDevices.txt" => string chuckProbeCmd;
        Std.system(chuckProbeCmd);

        FileIO fio;
        StringTokenizer tokenizer;
        string line;
        string token;

        ".midiDevices.txt" => fio.open;
        // Ensure file opened correctly
        if( !fio.good() ) {
            cherr <= "ERROR: Unable to open file/dir: " <= ".midiDevices.txt" <= " for reading."
                    <= IO.newline();
            me.exit();
        }

        0 => int processInputs;
        0 => int processOutputs;

        while (fio.more()) {
            fio.readLine() => line;
            line => tokenizer.set;

            if (tokenizer.size() == 1) {
                0 => processInputs;
                0 => processOutputs;
            }

            if (processInputs || processOutputs) {
                // [chuck]:  line start
                tokenizer.next();

                // Device ID
                tokenizer.next().charAt(1) - "0".charAt(0) => int deviceId;

                // Colon
                tokenizer.next();

                // Rest of the line is device name
                tokenizer.next() => string deviceName;
                while (tokenizer.more()) {
                    deviceName + " " + tokenizer.next() => deviceName;
                }

                // Remove " in beginning and end of name
                deviceName.substring(1, deviceName.length() - 2) => deviceName;

                if (processInputs) this.midiInDevices << new Enum(deviceId, deviceName);
                if (processOutputs) this.midiOutDevices << new Enum(deviceId, deviceName);
            }

            while ( tokenizer.more() && (!processInputs || !processOutputs) ) {
                tokenizer.next() => token;
                if (token == "MIDI") {
                    tokenizer.next() => token;
                    if (token == "input" || token == "inputs") 1 => processInputs;
                    if (token == "output" || token == "outputs") 1 => processOutputs;
                }
            }
        }
    }

    fun void save(string filename) {
        <<< "Saving Data" >>>;
        // Serialize the current state of the nodes
        HashMap nodes;
        HashMap connections;

        for (int idx; idx < this.nodesOnScreen.size(); idx++) {
            this.nodesOnScreen[idx] @=> Node node;
            nodes.set(idx, node.serialize());
        }

        for (int idx; idx < this.nodeConnections.size(); idx++) {
            this.nodeConnections[idx] @=> Connection conn;
            connections.set(idx, conn.serialize());
        }

        HashMap data;
        data.set("nodes", nodes);
        data.set("connections", connections);

        filename + ".json" => filename;
        SaveHandler.save(filename, data);
    }

    fun void loadSave(string filename) {
        filename + ".json" => filename;
        SaveHandler.load(filename) @=> HashMap data;

        // Load nodes and connections
        data.get("nodes") @=> HashMap nodes;
        data.get("connections") @=> HashMap connections;

        // Create and add nodes
        nodes.intKeys() @=> int nodeKeys[];
        nodeKeys.sort();
        for (int idx; idx < nodeKeys.size(); idx++) {
            nodes.get(idx) @=> HashMap nodeData;
            nodeData.getStr("nodeClass") => string nodeClassName;

            // Handle based on node class
            if (nodeClassName == MidiInNode.typeOf().name()) {
                nodeData.getStr("nodeID") => string nodeID;
                nodeData.getInt("midiID") => int midiID;
                nodeData.getInt("channel") => int channel;
                nodeData.getInt("synthMode") => int synthMode;
                nodeData.getInt("latch") => int latch;
                nodeData.getInt("numOutputs") => int numOutputs;
                nodeData.getInt("optionsActive") => int optionsActive;
                nodeData.getInt("inputsActive") => int inputsActive;
                nodeData.getInt("outputsActive") => int outputsActive;

                // Position
                nodeData.getFloat("posX") => float posX;
                nodeData.getFloat("posY") => float posY;
                nodeData.getFloat("posZ") => float posZ;

                // Create and add node
                MidiInNode midiIn(midiID, channel, numOutputs);
                midiIn.setNodeID(nodeID);
                midiIn.setChannel(channel);
                midiIn.synthMode(synthMode);
                midiIn.latch(latch);
                @(posX, posY, posZ) => midiIn.pos;
                this.addNode(midiIn);
                spork ~ midiIn.processMidi() @=> Shred @ midiInProcessMidiShred;
                spork ~ midiIn.processInputs() @=> Shred @ midiInProcessInputsShred;
                spork ~ midiIn.processNumberBoxUpdates() @=> Shred @ midiInProcessNumberBoxShred;
                midiIn.addShreds([midiInProcessMidiShred, midiInProcessInputsShred, midiInProcessNumberBoxShred]);

                // Handle options menu selections
                (midiIn.nodeOptionsBox$MidiOptionsBox).channelSelectMenu.updateSelectedEntry(channel + 1);  // +1 because 0th entry is "All"
                (midiIn.nodeOptionsBox$MidiOptionsBox).synthModeSelectMenu.updateSelectedEntry(synthMode);
                (midiIn.nodeOptionsBox$MidiOptionsBox).latchSelectMenu.updateSelectedEntry(latch);

                // Handle input data type mappings and menu selections
                nodeData.get("inputMenuData")$HashMap @=> HashMap inputMenuData;
                inputMenuData.intKeys() @=> int inputMenuDataKeys[];
                inputMenuDataKeys.sort();
                for (int idx; idx < inputMenuDataKeys.size(); idx++) {
                    inputMenuData.getInt(idx) => int midiInputTypeIdx;
                    if (midiInputTypeIdx == -1) continue;

                    MidiInputType.allTypes[midiInputTypeIdx] @=> Enum midiInputType;

                    // Update menu selection
                    midiIn.nodeInputsBox.menus[idx].updateSelectedEntry(midiInputTypeIdx);

                    // Update output data type mapping
                    midiIn.nodeInputsBox.setDataTypeMapping(midiInputType, idx);
                }

                // Handle output data type mappings and menu selections
                nodeData.get("outputMenuData")$HashMap @=> HashMap outputMenuData;
                nodeData.get("outputNumberBoxData")$HashMap @=> HashMap outputNumberBoxData;
                outputMenuData.intKeys() @=> int outputMenuDataKeys[];
                outputMenuDataKeys.sort();
                for (int idx; idx < outputMenuDataKeys.size(); idx++) {
                    outputMenuData.getInt(idx) => int midiDataTypeIdx;
                    if (midiDataTypeIdx == -1) continue;

                    MidiDataType.allTypes[midiDataTypeIdx] @=> Enum midiDataType;

                    // Update menu selection
                    midiIn.nodeOutputsBox.menus[idx].updateSelectedEntry(midiDataTypeIdx);

                    // Handle number entry box if needed
                    0 => int voiceIdx;
                    if (midiIn.nodeOutputsBox.hasNumberBox(midiDataType.id)) {
                        midiIn.nodeOutputsBox.showNumberBox(idx);
                        outputNumberBoxData.getInt(idx) => voiceIdx;
                        midiIn.nodeOutputsBox.numberBoxes[idx].set(voiceIdx);
                    }

                    // Update output data type mapping
                    midiIn.outputDataTypeIdx(midiDataType, voiceIdx, idx);
                }

                // Handle visibility
                if (!optionsActive) midiIn.hideOptionsBox();
                if (!inputsActive) midiIn.hideInputsBox();
                if (!outputsActive) midiIn.hideOutputsBox();

            } else if (nodeClassName == AudioInNode.typeOf().name()) {
                nodeData.getStr("nodeID") => string nodeID;
                nodeData.getFloat("posX") => float posX;
                nodeData.getFloat("posY") => float posY;
                nodeData.getFloat("posZ") => float posZ;

                AudioInNode audioIn(adc.channels());
                audioIn.setNodeID(nodeID);
                @(posX, posY, posZ) => audioIn.pos;
                this.addNode(audioIn);

            } else if (nodeClassName == AudioOutNode.typeOf().name()) {
                nodeData.getStr("nodeID") => string nodeID;
                nodeData.getFloat("posX") => float posX;
                nodeData.getFloat("posY") => float posY;
                nodeData.getFloat("posZ") => float posZ;

                AudioOutNode audioOut(dac.channels());
                audioOut.setNodeID(nodeID);
                @(posX, posY, posZ) => audioOut.pos;
                this.addNode(audioOut);

            } else if (nodeClassName == WavefolderNode.typeOf().name()) {
                nodeData.getStr("nodeID") => string nodeID;
                nodeData.getFloat("posX") => float posX;
                nodeData.getFloat("posY") => float posY;
                nodeData.getFloat("posZ") => float posZ;
                nodeData.getInt("numInputs") => int numInputs;

                WavefolderNode wavefolder(numInputs, 4.);
                wavefolder.setNodeID(nodeID);
                @(posX, posY, posZ) => wavefolder.pos;

                // Handle input data type mappings and menu selections
                nodeData.get("inputMenuData")$HashMap @=> HashMap inputMenuData;
                inputMenuData.intKeys() @=> int inputMenuDataKeys[];
                inputMenuDataKeys.sort();
                for (int idx; idx < inputMenuDataKeys.size(); idx++) {
                    inputMenuData.getInt(idx) @=> int wavefolderInputTypeIdx;

                    // Skip if no mapping
                    if (wavefolderInputTypeIdx == -1) continue;

                    // Get wavefolder input type
                    WavefolderInputType.allTypes[wavefolderInputTypeIdx] @=> Enum wavefolderInputType;

                    // Update menu selection
                    wavefolder.nodeInputsBox.menus[idx].updateSelectedEntry(wavefolderInputTypeIdx);

                    // Update input data type mapping
                    wavefolder.nodeInputsBox.setDataTypeMapping(wavefolderInputType, idx);
                }

                // Run wavefolder
                spork ~ wavefolder.processInputs() @=> Shred @ wavefolderProcessInputsShred;
                wavefolder.addShreds([wavefolderProcessInputsShred]);

                // Add node to screen
                this.addNode(wavefolder);
            } else if (nodeClassName == SequencerNode.typeOf().name()) {
                nodeData.getStr("nodeID") => string nodeID;
                nodeData.getFloat("posX") => float posX;
                nodeData.getFloat("posY") => float posY;
                nodeData.getFloat("posZ") => float posZ;
                nodeData.getInt("numInputs") => int numInputs;

                // Instantiate node
                SequencerNode sequencer(numInputs, 4.);
                sequencer.setNodeID(nodeID);
                @(posX, posY, posZ) => sequencer.pos;

                // Handle input data type mappings and menu selections
                nodeData.get("inputMenuData")$HashMap @=> HashMap inputMenuData;
                inputMenuData.intKeys() @=> int inputMenuDataKeys[];
                inputMenuDataKeys.sort();
                for (int idx; idx < inputMenuDataKeys.size(); idx++) {
                    inputMenuData.getInt(idx) @=> int sequencerInputTypeIdx;

                    // Skip if no mapping
                    if (sequencerInputTypeIdx == -1) continue;

                    // Get sequencer input type
                    SequencerInputType.allTypes[sequencerInputTypeIdx] @=> Enum sequencerInputType;

                    // Update menu selection
                    sequencer.nodeInputsBox.menus[idx].updateSelectedEntry(sequencerInputTypeIdx);

                    // Update input data type mapping
                    sequencer.nodeInputsBox.setDataTypeMapping(sequencerInputType, idx);
                }

                // Handle sequence data
                nodeData.get("sequenceData")$HashMap @=> HashMap sequenceList;
                sequenceList.intKeys() @=> int sequenceListKeys[];
                sequenceListKeys.sort();

                // Iterate through all sequences
                for (int sequenceIdx; sequenceIdx < sequenceListKeys.size(); sequenceIdx++) {
                    sequenceList.get(sequenceIdx)$HashMap @=> HashMap sequenceData;
                    sequenceData.intKeys() @=> int sequenceDataKeys[];
                    sequenceDataKeys.sort();

                    // Iterate through all records
                    Sequence currSequence;
                    for (int recordIdx; recordIdx < sequenceDataKeys.size(); recordIdx++) {
                        sequenceData.get(recordIdx)$HashMap @=> HashMap recordData;
                        recordData.getInt("data1") => int data1;
                        recordData.getInt("data2") => int data2;
                        recordData.getInt("data3") => int data3;
                        recordData.getFloat("timeSinceLast") => float timeSinceLast;
                        MidiRecord record(data1, data2, data3, timeSinceLast::samp);
                        currSequence.addRecord(record);
                    }
                    sequencer.sequences << currSequence;
                }


                // Run sequencer
                spork ~ sequencer.processInputs() @=> Shred @ sequencerProcessInputsShred;
                sequencer.addShreds([sequencerProcessInputsShred]);

                // Add node to screen
                this.addNode(sequencer);
            } else if (nodeClassName == TransportNode.typeOf().name()) {
                nodeData.getStr("nodeID") => string nodeID;
                nodeData.getFloat("posX") => float posX;
                nodeData.getFloat("posY") => float posY;
                nodeData.getFloat("posZ") => float posZ;
                nodeData.getFloat("tempo") => float tempo;
                nodeData.getFloat("beatDiv") => float beatDiv;

                TransportNode transport(tempo, beatDiv, 4.);
                transport.setNodeID(nodeID);
                @(posX, posY, posZ) => transport.pos;

                // Run transport
                spork ~ transport.processOptions() @=> Shred @ transportProcessOptionsShred;
                transport.addShreds([transportProcessOptionsShred]);

                // Add node to screen
                this.addNode(transport);
            } else if (nodeClassName == ScaleNode.typeOf().name()) {
                nodeData.getStr("nodeID") => string nodeID;
                nodeData.getFloat("posX") => float posX;
                nodeData.getFloat("posY") => float posY;
                nodeData.getFloat("posZ") => float posZ;
                nodeData.getFloat("inLow") => float inLow;
                nodeData.getFloat("inHigh") => float inHigh;
                nodeData.getFloat("outLow") => float outLow;
                nodeData.getFloat("outHigh") => float outHigh;

                ScaleNode scale(inLow, inHigh, outLow, outHigh, 1, 4.);
                scale.setNodeID(nodeID);
                @(posX, posY, posZ) => scale.pos;

                // Run scale
                spork ~ scale.processOptions() @=> Shred @ scaleProcessOptionsShred;
                scale.addShreds([scaleProcessOptionsShred]);

                // Add node to screen
                this.addNode(scale);
            }
        }

        // Create and add connections
        connections.intKeys() @=> int connectionKeys[];
        connectionKeys.sort();
        for (int idx; idx < connectionKeys.size(); idx++) {
            connections.get(idx) @=> HashMap connectionData;

            // Input Node
            connectionData.getStr("inputNodeID") => string inputNodeID;
            connectionData.getInt("inputNodeJackIdx") => int inputNodeJackIdx;
            connectionData.getFloat("inputJackPosX") => float inputJackPosX;
            connectionData.getFloat("inputJackPosY") => float inputJackPosY;

            // Output Node
            connectionData.getStr("outputNodeID") => string outputNodeID;
            connectionData.getInt("outputNodeJackIdx") => int outputNodeJackIdx;
            connectionData.getFloat("outputJackPosX") => float outputJackPosX;
            connectionData.getFloat("outputJackPosY") => float outputJackPosY;

            // Get nodes from node IDs
            Node @ inputNode;
            Node @ outputNode;
            for (Node node : this.nodesOnScreen) {
                if (node.nodeID == inputNodeID) node @=> inputNode;
                if (node.nodeID == outputNodeID) node @=> outputNode;
            }

            // Create and add connection
            Connection connection(outputNode, outputNodeJackIdx, @(outputJackPosX, outputJackPosY), @(0., 0., 0.));
            connection.completeWire(inputNode, inputNodeJackIdx, @(inputJackPosX, inputJackPosY));

            // Connect output data to input data
            outputNode.nodeOutputsBox.jacks[outputNodeJackIdx].ugen @=> UGen ugen;
            inputNode.connect(outputNode, ugen, inputNodeJackIdx);
            inputNode.nodeInputsBox.jacks[inputNodeJackIdx].setUgen(ugen);

            // Add connection to connections list
            this.nodeConnections << connection;
        }
    }

    fun void clearScreen() {
        <<< "Clearing screen" >>>;
        for (Connection conn : this.nodeConnections) {
            conn.deleteWire();
        }

        for (Node node : this.nodesOnScreen) {
            node.deactivateNode();
            node --< GG.scene();
        }

        // Clear nodes
        this.nodesOnScreen.clear();
        0 => this.numNodes;

        0 => this.nodeSelected;
        -1 => this.currSelectedNodeIdx;
        null => this.currSelectedNode;

        0 => this.nodeHeld;
        -1 => this.currHeldNodeIdx;
        null => this.currHeldNode;

        // Clear connections
        this.nodeConnections.clear();
        0 => this.openConnection;
        null => this.currOpenConnection;

        0 => this.connectionSelected;
        -1 => this.currSelectedConnectionIdx;
        null => this.currSelectedConnection;

        // Menus
        0 => this.menuOpen;
        null => this.currMenu;
    }

    fun void run() {

        // Declare previous mouse position, which for first frame will just be current pos
        GG.camera().screenCoordToWorldPos(GWindow.mousePos(), 1) => vec3 mousePrevWorldPos;

        while (true) {
            // Mouse pos in screen coordinates
            GWindow.mousePos() => vec2 mouseCoordPos;

            // Mouse pos and delta in World coordinates
            GG.camera().screenCoordToWorldPos(mouseCoordPos, 1) => vec3 mouseWorldPos;
            @(mouseWorldPos.x - mousePrevWorldPos.x, mouseWorldPos.y - mousePrevWorldPos.y, 0) => vec3 mouseWorldDelta;

            // Update prev mouse world pos after delta has been calculated
            mouseWorldPos => mousePrevWorldPos;

            // Mouse Click Down on this frame
            if (GWindow.mouseLeftDown() == 1) {

                // If a menu is open, check if clicking on a menu entry item
                // We check this here before checking nodes, because a dropdown menu
                // can extend beyond the Node's Y position, which would skip any processing
                // handled in the Node conditionals
                -1 => int dropdownMenuEntryIdx;
                if (this.menuOpen) {
                    this.currMenu.parent()$IOBox @=> IOBox ioBoxParent;
                    ioBoxParent.parent()$Node @=> Node parent;
                    this.currMenu.mouseHoverEntry(mouseWorldPos, parent, ioBoxParent) => dropdownMenuEntryIdx;
                }

                // Update menu entry
                if (dropdownMenuEntryIdx != -1) {
                    this.currMenu.getSelectedEntry() @=> Enum previousSelection;
                    this.currMenu.updateSelectedEntry(dropdownMenuEntryIdx);
                    this.currMenu.getSelectedEntry() @=> Enum newSelection;

                    // Make updates based on menu selection
                    Type.of(this.currMenu.parent()).name() => string menuParentName;

                    if (menuParentName == IOBox.typeOf().name()) {
                        this.currMenu.parent()$IOBox @=> IOBox ioBox;
                        ioBox.parent()$Node @=> Node node;

                        if (ioBox.ioType == IOType.INPUT) {
                            // MIDI nodes
                            if (Type.of(node).name() == MidiInNode.typeOf().name()) {
                                node$MidiInNode @=> MidiInNode midiIn;

                                // Set input data type mapping for MIDI node
                                midiIn.nodeInputsBox.setDataTypeMapping(this.currMenu.getSelectedEntry(), this.currMenu.menuIdx);
                            }

                            // Effect nodes
                            if (Type.of(node).name() == WavefolderNode.typeOf().name()) {
                                node$WavefolderNode @=> WavefolderNode wavefolder;

                                // Set input data type mapping for Wavefolder node
                                wavefolder.nodeInputsBox.setDataTypeMapping(this.currMenu.getSelectedEntry(), this.currMenu.menuIdx);
                            }

                            // Sequencer nodes
                            if (Type.of(node).name() == SequencerNode.typeOf().name()) {
                                node$SequencerNode @=> SequencerNode sequencer;

                                // Set input data type mapping for Wavefolder node
                                sequencer.nodeInputsBox.setDataTypeMapping(this.currMenu.getSelectedEntry(), this.currMenu.menuIdx);
                            }

                            // Utility nodes
                            if (Type.of(node).name() == ScaleNode.typeOf().name()) {
                                node$ScaleNode @=> ScaleNode scale;

                                // Set input data type
                                scale.nodeInputsBox.setDataTypeMapping(this.currMenu.getSelectedEntry(), this.currMenu.menuIdx);
                            }
                        } else if (ioBox.ioType == IOType.OUTPUT) {
                            if (Type.of(node).name() == MidiInNode.typeOf().name()) {
                                node$MidiInNode @=> MidiInNode midiIn;
                                // Remove old mapping
                                midiIn.removeOutputDataTypeMapping(previousSelection, 0);

                                // Check if number entry box is needed
                                0 => int voiceIdx;
                                if (midiIn.nodeOutputsBox.hasNumberBox(newSelection.id)) {
                                    midiIn.nodeOutputsBox.showNumberBox(this.currMenu.menuIdx);
                                } else {
                                    midiIn.nodeOutputsBox.hideNumberBox(this.currMenu.menuIdx);
                                }

                                // Add new mapping
                                midiIn.outputDataTypeIdx(newSelection, voiceIdx, this.currMenu.menuIdx);
                            }
                        }
                    }

                    // Close menu
                    this.currMenu.collapse();
                    0 => this.menuOpen;
                    null => this.currMenu;
                }

                // click in node
                -1 => int clickedNodeIdx;
                0 => int connectionCompletedThisFrame;

                // Check if clicking on an on-screen Node
                for (int nodeIdx; nodeIdx < this.nodesOnScreen.size(); nodeIdx++) {
                    this.nodesOnScreen[nodeIdx] @=> Node node;

                    // Check if mouse is over this node's name box
                    node.mouseOverNameBox(mouseWorldPos) => int nodeNameHover;
                    if (nodeNameHover) {
                        1 => this.nodeSelected;
                        nodeIdx => this.currSelectedNodeIdx;
                        node @=> this.currSelectedNode;

                        // Found the node that was clicked on, can exit early
                        nodeIdx => clickedNodeIdx;
                        break;
                    }

                    // Check if mouse is over this node's options box
                    int nodeOptionsBoxIteractedWith;
                    node.mouseOverOptionsBox(mouseWorldPos) => int nodeOptionsHover;
                    if (nodeOptionsHover && node.nodeOptionsBox.active || (node.nodeOptionsBox != null && node.nodeOptionsBox.menuOpen)) {
                        <<< "Clicked on node option's box" >>>;
                        node.nodeOptionsBox.handleMouseLeftDown(mouseWorldPos) => nodeOptionsBoxIteractedWith;

                        if (node.nodeOptionsBox.entryBoxSelected) {
                            node.nodeOptionsBox.selectedEntryBox @=> this.currNumberBox;
                            1 => this.numberBoxSelected;
                            node.nodeOptionsBox.selectedEntryBox.numberBoxIdx => this.currNumberBoxIdx;

                            // Reset selection in OptionsBox, NodeManager takes care of the rest
                            0 => node.nodeOptionsBox.entryBoxSelected;
                        }

                        // Found the node that was clicked on, can exit early
                        if (nodeOptionsBoxIteractedWith) {
                            nodeIdx => clickedNodeIdx;
                            break;
                        }
                    }

                    // Check if mouse is over this node's nodeInputsBox
                    // This would be for completing a connection
                    node.mouseOverInputsBox(mouseWorldPos) => int nodeInputsBoxHover;
                    if (nodeInputsBoxHover && node.nodeInputsBox.active && !nodeOptionsBoxIteractedWith) {
                        // Check if clicking on an Input jack
                        node.nodeInputsBox.mouseOverJack(mouseWorldPos) => int jackIdx;
                        if (jackIdx != -1) {
                            node.nodeInputsBox.jacks[jackIdx] @=> Jack jack;
                            node.inputJackPos(jackIdx) => vec2 jackPos;

                            // If clicking on an Input jack, must be completing a connection
                            // Otherwise, ignore the click
                            if (this.openConnection == 1) {
                                // Jacks from an nodeInputsBox are always Input jacks
                                this.currOpenConnection.completeWire(node, jackIdx, jackPos);

                                // Connect output data to input data
                                this.currOpenConnection.outputNode.nodeOutputsBox.jacks[this.currOpenConnection.outputNodeJackIdx].ugen @=> UGen ugen;
                                this.currOpenConnection.inputNode.connect(this.currOpenConnection.outputNode, ugen, this.currOpenConnection.inputNodeJackIdx);
                                this.currOpenConnection.inputNode.nodeInputsBox.jacks[this.currOpenConnection.inputNodeJackIdx].setUgen(ugen);
                                // Add connection to connections list
                                this.nodeConnections << this.currOpenConnection;

                                // Remove open connection
                                0 => this.openConnection;
                                null => this.currOpenConnection;

                                // Set connection complete this frame
                                1 => connectionCompletedThisFrame;
                            }
                        }

                        // Check if clicking on a menu
                        node.nodeInputsBox.mouseOverDropdownMenu(mouseWorldPos) => int dropdownMenuIdx;
                        if (dropdownMenuIdx != -1 && jackIdx == -1 && dropdownMenuEntryIdx == -1 && !nodeOptionsBoxIteractedWith) {
                            <<< "Clicked on", node.nodeInputsBox.menus[dropdownMenuIdx].menuID >>>;

                            // No existing menu opened
                            if (!this.menuOpen) {
                                node.nodeInputsBox.menus[dropdownMenuIdx] @=> this.currMenu;
                                this.currMenu.expand();
                                1 => this.menuOpen;
                            }
                        // Close active menu if Menu is open and click outside of menu
                        } else if (dropdownMenuIdx == -1 && dropdownMenuEntryIdx == -1 && this.menuOpen) {
                            this.currMenu.collapse();
                            0 => this.menuOpen;
                            null => this.currMenu;
                        }

                        // Found the node that was clicked on, can exit early
                        nodeIdx => clickedNodeIdx;
                        break;
                    }

                    // Check if 1) the mouse is over this node's IO modifier box for an nodeInputsBox and 2) not in an open menu
                    int nodeInputsModifierInteractedWith;
                    node.mouseOverInputsModifierBox(mouseWorldPos) => int nodeInputsModifierHover;
                    if (nodeInputsModifierHover && node.nodeInputsModifierBox.active && dropdownMenuEntryIdx == -1 && !nodeOptionsBoxIteractedWith) {
                        node.nodeInputsModifierBox.mouseOverModifiers(mouseWorldPos) => int jackModifier;
                        if (jackModifier == IOModifierBox.ADD) {
                            node.addJack(IOType.INPUT);
                            1 => nodeInputsModifierInteractedWith;
                        } else if (jackModifier == IOModifierBox.REMOVE && node.nodeInputsBox.numJacks > 1) {
                            node.nodeInputsBox.numJacks - 1 => int removedJackIdx;

                            // TODO: Remove the connection

                            node.removeJack(IOType.INPUT);
                            1 => nodeInputsModifierInteractedWith;

                        }
                    }

                    // Check if 1) the mouse is over this node's IO modifier box for an nodeOutputsBox and 2) not in an open menu
                    node.mouseOverOutputsModifierBox(mouseWorldPos) => int nodeOutputsModifierHover;
                    if (nodeOutputsModifierHover && node.nodeOutputsModifierBox.active && dropdownMenuEntryIdx == -1 && !nodeOptionsBoxIteractedWith) {
                        node.nodeOutputsModifierBox.mouseOverModifiers(mouseWorldPos) => int jackModifier;
                        if (jackModifier == IOModifierBox.ADD) {
                            node.addJack(IOType.OUTPUT);  // Call on the Node directly
                        } else if (jackModifier == IOModifierBox.REMOVE && node.nodeOutputsBox.numJacks > 1) {
                            // If removed jack has a connection, remove it
                            node.nodeOutputsBox.numJacks - 1 => int removedJackIdx;

                            -1 => int removedConnectionIdx;
                            for (int connIdx; connIdx < this.nodeConnections.size(); connIdx++) {
                                this.nodeConnections[connIdx] @=> Connection conn;
                                if (
                                    (conn.outputNode.nodeID == node.nodeID && conn.outputNodeJackIdx == removedJackIdx)
                                    || (conn.inputNode.nodeID == node.nodeID && conn.inputNodeJackIdx == removedJackIdx)
                                ) {
                                    connIdx => removedConnectionIdx;
                                    break;
                                }
                            }

                            if (removedConnectionIdx != -1) {
                                this.nodeConnections[removedConnectionIdx] @=> Connection conn;

                                // Remove the connection UGen mapping
                                conn.outputNode.nodeOutputsBox.jacks[conn.outputNodeJackIdx].ugen @=> UGen ugen;
                                conn.inputNode.disconnect(conn.outputNode, ugen, conn.inputNodeJackIdx);
                                conn.inputNode.nodeInputsBox.jacks[conn.inputNodeJackIdx].removeUgen();

                                // Delete the wire
                                conn.deleteWire();

                                // Remove connection from connection list
                                this.nodeConnections.erase(removedConnectionIdx);
                            }
                            node.removeJack(IOType.OUTPUT);  // Call on the Node directly
                        }

                        // Found the node that was clicked on, can exit early
                        nodeIdx => clickedNodeIdx;
                        break;
                    }

                    // Check if mouse is over this node's nodeOutputsBox
                    // This would be for starting a new connection
                    node.mouseOverOutputsBox(mouseWorldPos) => int nodeOutputsBoxHover;
                    if (nodeOutputsBoxHover && node.nodeOutputsBox.active && !nodeOptionsBoxIteractedWith) {
                        <<< "Clicked on node outputs box", node.nodeID >>>;
                        // Check if clicking on an Output jack
                        node.nodeOutputsBox.mouseOverJack(mouseWorldPos) => int jackIdx;
                        if (jackIdx != -1) {
                            node.outputJackPos(jackIdx) => vec2 jackPos;

                            // Check if starting a new connection
                            // Jack's from an nodeOutputsBox are always Output jacks
                            if (this.openConnection == 0) {
                                <<< "Starting a new Connection" >>>;
                                Connection newConnection(node, jackIdx, jackPos, mouseWorldPos);
                                newConnection @=> this.currOpenConnection;
                                1 => this.openConnection;
                            } else {
                                // Completing a connection needs to be an Input jack
                                // Output to Output == delete the connection
                                this.currOpenConnection.deleteWire();
                                0 => this.openConnection;
                                null => this.currOpenConnection;
                            }
                        }

                        // Check if clicking on a menu
                        node.nodeOutputsBox.mouseOverDropdownMenu(mouseWorldPos) => int dropdownMenuIdx;
                        if (dropdownMenuIdx != -1 && jackIdx == -1 && dropdownMenuEntryIdx == -1 && !nodeOptionsBoxIteractedWith) {
                            <<< "Clicked on", node.nodeOutputsBox.menus[dropdownMenuIdx].menuID >>>;

                            // No existing menu opened
                            if (!this.menuOpen) {
                                node.nodeOutputsBox.menus[dropdownMenuIdx] @=> this.currMenu;
                                this.currMenu.expand();
                                1 => this.menuOpen;
                            }
                        // Close active menu if Menu is open and click outside of menu
                        } else if (dropdownMenuIdx == -1 && dropdownMenuEntryIdx == -1 && this.menuOpen) {
                            this.currMenu.collapse();
                            0 => this.menuOpen;
                            null => this.currMenu;
                        }

                        // Check if clicking on a number box
                        node.nodeOutputsBox.mouseOverNumberBox(mouseWorldPos) => int numberBoxIdx;
                        if (numberBoxIdx != -1) {
                            node.nodeOutputsBox.numberBoxes[numberBoxIdx] @=> this.currNumberBox;
                            1 => this.numberBoxSelected;
                            numberBoxIdx => this.currNumberBoxIdx;
                        }

                        // Found the node that was clicked on, can exit early
                        nodeIdx => clickedNodeIdx;
                        break;
                    }

                    // Check if clicking on a node's visibility box
                    int nodeVisibilityBoxIteractedWith;
                    node.mouseOverVisibilityBox(mouseWorldPos) => int nodeVisibilityBoxHover;
                    if (nodeVisibilityBoxHover && dropdownMenuEntryIdx == -1 && !nodeOptionsBoxIteractedWith) {
                        node.nodeVisibilityBox.mouseHoverModifiers(mouseWorldPos) => int visibilityModifier;
                        if (visibilityModifier == VisibilityBox.OPTIONS_BOX && node.nodeOptionsBox != null) {
                            if (node.nodeOptionsBox.active) {
                                node.hideOptionsBox();
                            } else {
                                node.showOptionsBox();
                            }
                            1 => nodeVisibilityBoxIteractedWith;
                        } else if (visibilityModifier == VisibilityBox.INPUTS_BOX && node.nodeInputsBox != null) {
                            if (node.nodeInputsBox.active) {
                                node.hideInputsBox();
                            } else {
                                node.showInputsBox();
                            }
                            1 => nodeVisibilityBoxIteractedWith;
                        } else if (visibilityModifier == VisibilityBox.OUTPUTS_BOX && node.nodeOutputsBox != null) {
                            if (node.nodeOutputsBox.active) {
                                node.hideOutputsBox();
                            } else {
                                node.showOutputsBox();
                            }
                            1 => nodeVisibilityBoxIteractedWith;
                        }
                    }

                    // Update this node's connection positions
                    if (nodeVisibilityBoxIteractedWith || nodeInputsModifierInteractedWith) {
                        // Update the position of all wires connected to this node
                        for (Connection conn : this.nodeConnections) {
                            if (node.nodeID == conn.outputNode.nodeID) {
                                // Update Connection start (i.e. Output Jack position)
                                node.outputJackPos(conn.outputNodeJackIdx) => vec2 jackPos;
                                conn.updateWireStartPos(jackPos);
                            } else if (node.nodeID == conn.inputNode.nodeID) {
                                // Update Connection end (i.e. Input Jack position)
                                node.inputJackPos(conn.inputNodeJackIdx) => vec2 jackPos;
                                conn.updateWireEndPos(jackPos);
                            }
                        }

                        nodeIdx => clickedNodeIdx;
                        break;
                    }
                }

                // Check if clicking on a connection wire
                -1 => int clickedConnectionIdx;
                for (int connIdx; connIdx < this.nodeConnections.size(); connIdx++) {
                    this.nodeConnections[connIdx] @=> Connection conn;
                    conn.mouseOverWire(mouseWorldPos) => int hoverOverWire;
                    if (hoverOverWire && !connectionCompletedThisFrame) {
                        // If a wire is already selected, unselect that wire
                        if (this.connectionSelected) this.currSelectedConnection.unselectWire();

                        connIdx => clickedConnectionIdx;
                        connIdx => this.currSelectedConnectionIdx;
                        1 => this.connectionSelected;
                        conn @=> this.currSelectedConnection;
                        conn.selectWire();
                        break;
                    }
                }

                // Remove connection selection if clicked on something else
                if (this.connectionSelected && clickedConnectionIdx == -1) {
                    this.currSelectedConnection.unselectWire();
                    0 => this.connectionSelected;
                    -1 => this.currSelectedConnectionIdx;
                    null => this.currSelectedConnection;
                }

                // If clicked outside of a node and a menu is open, close the menu
                if (clickedNodeIdx == -1 && this.menuOpen) {
                    this.currMenu.collapse();
                    0 => this.menuOpen;
                    null => this.currMenu;
                // If clicked outside of a node and a node is selected, remove the selection
                } else if (clickedNodeIdx == -1 && this.nodeSelected) {
                    0 => this.nodeSelected;
                    -1 => this.currSelectedNodeIdx;
                    null => this.currSelectedNode;
                // If clicked outside of a node and a number box is selected, remove the selection
                } else if (clickedNodeIdx == -1 && this.numberBoxSelected) {
                    // Signal the update event
                    this.currNumberBox.signalUpdate();

                    // Remove the selection
                    0 => this.numberBoxSelected;
                    -1 => this.currNumberBoxIdx;
                    null => this.currNumberBox;
                }
            }

            // Check if mouse left click is held down
            if (GWindow.mouseLeft()) {

                if (!this.nodeHeld) {
                    // Check if clicking on an on-screen Node
                    for (int nodeIdx; nodeIdx < this.nodesOnScreen.size(); nodeIdx++) {
                        this.nodesOnScreen[nodeIdx] @=> Node node;

                        // Check if mouse is over this node's name box
                        node.mouseOverNameBox(mouseWorldPos) => int nodeNameHover;
                        if (nodeNameHover) {
                            1 => this.nodeHeld;
                            nodeIdx => this.currHeldNodeIdx;
                            node @=> this.currHeldNode;
                            break;
                        }
                    }
                }

                // Move node if its being held down
                if (this.nodeHeld) {
                    this.currHeldNode.translate(mouseWorldDelta);

                    // Update the position of all wires connected to this node
                    for (Connection conn : this.nodeConnections) {
                        if (this.currHeldNode.nodeID == conn.outputNode.nodeID) {
                            // Update Connection start (i.e. Output Jack position)
                            this.currHeldNode.outputJackPos(conn.outputNodeJackIdx) => vec2 jackPos;
                            conn.updateWireStartPos(jackPos);
                        } else if (this.currHeldNode.nodeID == conn.inputNode.nodeID) {
                            // Update Connection end (i.e. Input Jack position)
                            this.currHeldNode.inputJackPos(conn.inputNodeJackIdx) => vec2 jackPos;
                            conn.updateWireEndPos(jackPos);
                        }
                    }
                }
            }

            // Check if mouse left click is released
            if (GWindow.mouseLeftUp()) {

                // If a node was being held to move it, stop tracking it
                if (this.nodeHeld) {
                    -1 => this.currHeldNodeIdx;
                    0 => this.nodeHeld;
                    null => this.currHeldNode;
                }
            }

            // Handle scroll wheel
            GWindow.scrollY() => float mouseWheelScrollY;
            if (mouseWheelScrollY != 0) {
                mouseWheelScrollY / 10. => float translateVal;
                if (GWindow.key(GWindow.Key_LeftAlt)) {
                    GG.scene().camera().translateX(translateVal);
                    this.moveCameraEvent.set(translateVal, 0.);
                    this.moveCameraEvent.signal();
                }
                else {
                    GG.scene().camera().translateY(translateVal);
                    this.moveCameraEvent.set(0., translateVal);
                    this.moveCameraEvent.signal();
                }
            }

            // Check if BACKSPACE key is pressed
            if (GWindow.keyDown(GWindow.Key_Backspace)) {
                // If a connection is selected, delete the connection
                if (this.connectionSelected) {
                    // Remove the connection UGen mapping
                    this.currSelectedConnection.outputNode.nodeOutputsBox.jacks[this.currSelectedConnection.outputNodeJackIdx].ugen @=> UGen ugen;
                    this.currSelectedConnection.inputNode.disconnect(this.currSelectedConnection.outputNode, ugen, this.currSelectedConnection.inputNodeJackIdx);
                    this.currSelectedConnection.inputNode.nodeInputsBox.jacks[this.currSelectedConnection.inputNodeJackIdx].removeUgen();

                    // Delete the wire
                    this.currSelectedConnection.deleteWire();

                    // Remove the connection from the connections list
                    this.nodeConnections.erase(this.currSelectedConnectionIdx);

                    // Unset selected connection variables
                    0 => this.connectionSelected;
                    -1 => this.currSelectedConnectionIdx;
                    null => this.currSelectedConnection;
                // If a node is selected, delete the node
                } else if (this.nodeSelected && !this.numberBoxSelected) {
                    this.removeNode(this.currSelectedNode);

                    0 => this.nodeSelected;
                    -1 => this.currSelectedNodeIdx;
                    null => this.currSelectedNode;
                } else if (this.numberBoxSelected) {
                    this.currNumberBox.removeNumberChar();
                }
            }

            // Check if ENTER key is pressed
            if (GWindow.keyDown(GWindow.Key_Enter)) {
                if (this.numberBoxSelected) {
                    // Update the node's output data type mapping
                    this.currNumberBox.signalUpdate();

                    0 => this.numberBoxSelected;
                    -1 => this.currNumberBoxIdx;
                    null => this.currNumberBox;
                }
            }

            // Check if CMD+S is pressed
            if (GWindow.key(GWindow.Key_LeftSuper) && GWindow.keyDown(GWindow.Key_S)) {
                // <<< "Saving Data" >>>;
                // // Serialize the current state of the nodes
                // HashMap nodes;
                // HashMap connections;

                // for (int idx; idx < this.nodesOnScreen.size(); idx++) {
                //     this.nodesOnScreen[idx] @=> Node node;
                //     nodes.set(idx, node.serialize());
                // }

                // for (int idx; idx < this.nodeConnections.size(); idx++) {
                //     this.nodeConnections[idx] @=> Connection conn;
                //     connections.set(idx, conn.serialize());
                // }

                // HashMap data;
                // data.set("nodes", nodes);
                // data.set("connections", connections);

                // SaveHandler.save("autosave.json", data);
                this.save("autosave");
            }

            // All Keys pressed this frame
            GWindow.keysDown() @=> int keysPressed[];
            for (int key : keysPressed) {

                // If a number box is selected and a number key is pressed, add the number to the number box
                if (key >= GWindow.Key_0 && key <= GWindow.Key_9) {
                    if (this.numberBoxSelected) {
                        this.currNumberBox.addNumberChar(key - GWindow.Key_0);
                    }
                }

                if (key == GWindow.Key_Minus) {
                    if (this.numberBoxSelected) this.currNumberBox.addSpecialChar("-");
                }

                if (key == GWindow.Key_Period) {
                    if (this.numberBoxSelected) this.currNumberBox.addSpecialChar(".");
                }
            }

            // Handle moving wire for open connection
            if (this.openConnection == 1) {
                this.currOpenConnection.updateWire(mouseWorldPos);
            }

            // Highlight menu item if mouse hovers over it
            if (this.menuOpen) {
                this.currMenu.parent()$IOBox @=> IOBox ioBoxParent;
                ioBoxParent.parent()$Node @=> Node parent;
                this.currMenu.mouseHoverEntry(mouseWorldPos, parent, ioBoxParent) => int hoveredMenuEntryIdx;
                this.currMenu.highlightHoveredEntry(hoveredMenuEntryIdx);
            }

            // Handle mouse over each node's options box, if applicable
            for (Node node : this.nodesOnScreen) {
                if (node.nodeOptionsBox != null) {
                    node.nodeOptionsBox.handleMouseOver(mouseWorldPos);
                }
            }

            GG.nextFrame() => now;
        }
    }
}
