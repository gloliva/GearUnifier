// Imports
@import "../events.ck"
@import "../ui/menu.ck"
@import "base.ck"
@import "midi.ck"


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
                conn.inputNode.disconnect(ugen, conn.inputNodeJackIdx);
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
                spork ~ midiIn.run();
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
                if (this.menuOpen) this.currMenu.mouseHoverEntry(mouseWorldPos) => dropdownMenuEntryIdx;

                // Update menu entry
                if (dropdownMenuEntryIdx != -1) {
                    this.currMenu.getSelectedEntry() @=> Enum previousSelection;
                    this.currMenu.updateSelectedEntry(dropdownMenuEntryIdx);

                    // Make updates based on menu selection
                    Type.of(this.currMenu.parent()).name() => string menuParentName;

                    if (menuParentName == "MidiInNode") {
                        this.currMenu.parent()$MidiInNode @=> MidiInNode midiIn;
                        // Remove old mapping
                        midiIn.removeOutputDataTypeMapping(previousSelection, 0);

                        // Add new mapping
                        midiIn.outputDataTypeIdx(this.currMenu.getSelectedEntry(), 0, this.currMenu.menuIdx);
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
                        <<< "clicked on node name box", node.nodeID >>>;
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
                    if (nodeOptionsHover || (node.nodeOptionsBox != null && node.nodeOptionsBox.menuOpen)) {
                        <<< "Clicked on node option's box" >>>;
                        node.nodeOptionsBox.handleMouseLeftDown(mouseWorldPos) => nodeOptionsBoxIteractedWith;

                        // Found the node that was clicked on, can exit early
                        if (nodeOptionsBoxIteractedWith) {
                            nodeIdx => clickedNodeIdx;
                            break;
                        }
                    }

                    // Check if mouse is over this node's nodeInputsBox
                    // This would be for completing a connection
                    node.mouseOverInputsBox(mouseWorldPos) => int nodeInputsBoxHover;
                    if (nodeInputsBoxHover == 1 && !nodeOptionsBoxIteractedWith) {
                        // Check if clicking on an Input jack
                        node.nodeInputsBox.mouseHoverOverJack(mouseWorldPos) => int jackIdx;
                        if (jackIdx != -1) {
                            node.nodeInputsBox.jacks[jackIdx] @=> Jack jack;
                            @(node.posX() + jack.posX() * jack.scaX(), node.posY() + jack.posY() * jack.scaY()) => vec2 jackPos;

                            // If clicking on an Input jack, must be completing a connection
                            // Otherwise, ignore the click
                            if (this.openConnection == 1) {
                                // Jacks from an nodeInputsBox are always Input jacks
                                this.currOpenConnection.completeWire(node, jackIdx, jackPos);

                                // Connect output data to input data
                                this.currOpenConnection.outputNode.nodeOutputsBox.jacks[this.currOpenConnection.outputNodeJackIdx].ugen @=> UGen ugen;
                                this.currOpenConnection.inputNode.connect(ugen, this.currOpenConnection.inputNodeJackIdx);
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

                        // Check if mouse is over this node's nodeOutputsBox
                        // This would be for starting a new connection
                        node.mouseOverOutputsBox(mouseWorldPos) => int nodeOutputsBoxHover;
                        if (nodeOutputsBoxHover == 1 && !nodeOptionsBoxIteractedWith) {
                            // Check if clicking on an Output jack
                            node.nodeOutputsBox.mouseHoverOverJack(mouseWorldPos) => int jackIdx;
                            if (jackIdx != -1) {
                                node.nodeOutputsBox.jacks[jackIdx] @=> Jack jack;
                                @(node.posX() + jack.posX() * jack.scaX(), node.posY() + jack.posY() * jack.scaY()) => vec2 jackPos;  // TODO: update this to use correct jack position based on IObox scale and position

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

                            // Check if 1) the mouse is over this node's IO modifier box for an nodeOutputsBox and 2) not in an open menu
                            node.nodeOutputsBox.mouseOverIOModifierBox(mouseWorldPos) => int nodeIOModifierHover;
                            if (nodeIOModifierHover && jackIdx == -1 && dropdownMenuIdx == -1 && dropdownMenuEntryIdx == -1 && !nodeOptionsBoxIteractedWith) {
                                node.nodeOutputsBox.ioModifierBox.mouseHoverModifiers(mouseWorldPos) => int jackModifier;
                                if (jackModifier == JackModifierBox.ADD) {
                                    node.addJack();  // Call on the Node directly, not the IO box
                                } else if (jackModifier == JackModifierBox.REMOVE && node.nodeOutputsBox.numJacks > 1) {
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
                                        conn.inputNode.disconnect(ugen, conn.inputNodeJackIdx);
                                        conn.inputNode.nodeInputsBox.jacks[conn.inputNodeJackIdx].removeUgen();

                                        // Delete the wire
                                        conn.deleteWire();

                                        // Remove connection from connection list
                                        this.nodeConnections.erase(removedConnectionIdx);
                                    }
                                    node.removeJack();  // Call on the Node directly, not the IO box
                                }
                            }
                        }

                        // Found the node that was clicked on, can exit early
                        nodeIdx => clickedNodeIdx;
                        break;
                    }

                    // Check if clicking on a node's visibility box
                    node.mouseOverVisibilityBox(mouseWorldPos) => int nodeVisibilityBoxHover;
                    if (nodeVisibilityBoxHover && dropdownMenuEntryIdx == -1 && !nodeOptionsBoxIteractedWith) {
                        // TODO: Implement visibility box handling for each content box section

                        // node.nodeVisibilityBox.mouseHoverModifiers(mouseWorldPos) => int visibilityModifier;
                        // if (visibilityModifier == VisibilityBox.OPTIONS_BOX) {
                        //     if (node.nodeOptionsBox.active) {
                        //         node.hideOptionsBox();
                        //     } else {
                        //         node.showOptionsBox();
                        //     }
                        // } else if (visibilityModifier == VisibilityBox.IO_BOX) {
                        //     if (node.jackModifierBox.active) {
                        //         node.hideIOBox();
                        //     } else {
                        //         node.showIOBox();
                        //     }
                        // }
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
                            this.currHeldNode.nodeOutputsBox.jacks[conn.outputNodeJackIdx] @=> Jack jack;
                            @(this.currHeldNode.posX() + jack.posX() * jack.scaX(), this.currHeldNode.posY() + jack.posY() * jack.scaY()) => vec2 jackPos;
                            conn.updateWireStartPos(jackPos);
                        } else if (this.currHeldNode.nodeID == conn.inputNode.nodeID) {
                            // Update Connection end (i.e. Input Jack position)
                            this.currHeldNode.nodeInputsBox.jacks[conn.inputNodeJackIdx] @=> Jack jack;
                            @(this.currHeldNode.posX() + jack.posX() * jack.scaX(), this.currHeldNode.posY() + jack.posY() * jack.scaY()) => vec2 jackPos;
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

            // Check if BACKSPACE key is pressed
            if (GWindow.keyDown(GWindow.Key_Backspace)) {
                // If a connection is selected, delete the connection
                if (this.connectionSelected) {
                    // Remove the connection UGen mapping
                    this.currSelectedConnection.outputNode.nodeOutputsBox.jacks[this.currSelectedConnection.outputNodeJackIdx].ugen @=> UGen ugen;
                    this.currSelectedConnection.inputNode.disconnect(ugen, this.currSelectedConnection.inputNodeJackIdx);
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
                } else if (this.nodeSelected) {
                    this.removeNode(this.currSelectedNode);

                    0 => this.nodeSelected;
                    -1 => this.currSelectedNodeIdx;
                    null => this.currSelectedNode;
                }
            }

            // Handle moving wire for open connection
            if (this.openConnection == 1) {
                this.currOpenConnection.updateWire(mouseWorldPos);
            }

            // Highlight menu item if mouse hovers over it
            if (this.menuOpen) {
                this.currMenu.mouseHoverEntry(mouseWorldPos) => int hoveredMenuEntryIdx;
                this.currMenu.highlightHoveredEntry(hoveredMenuEntryIdx);
            }

            // Handle mouse over each node's options box, if applicable
            for (Node node : this.nodesOnScreen) {
                if (node.nodeOptionsBox != null && node.nodeOptionsBox.menuOpen) {
                    node.nodeOptionsBox.handleMouseOver(mouseWorldPos);
                }
            }

            GG.nextFrame() => now;
        }
    }
}
