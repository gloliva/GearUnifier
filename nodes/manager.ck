// Imports
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

    // Held Node
    int nodeHeld;
    int currHeldNodeIdx;
    Node @ currHeldNode;

    // Selected Connection
    int connectionSelected;
    int currSelectedConnectionIdx;
    Connection @ currSelectedConnection;

    fun void addNode(Node node) {
        this.nodesOnScreen << node;
        this.numNodes++;
    }

    fun void removeNode(Node node) {
        -1 => int nodePos;
        for (int idx; idx < this.numNodes; idx++) {
            if (this.nodesOnScreen[idx].nodeID == node.nodeID) {
                idx => nodePos;
                break;
            }
        }

        // Remove node if in list
        if (nodePos != -1) {
            this.nodesOnScreen.popOut(nodePos);
            this.numNodes--;
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

                // Check if clicking on a connection wire
                -1 => int clickedConnectionIdx;
                for (int connIdx; connIdx < this.nodeConnections.size(); connIdx++) {
                    this.nodeConnections[connIdx] @=> Connection conn;
                    conn.mouseHoverOverWire(mouseWorldPos) => int hoverOverWire;
                    if (hoverOverWire) {
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

                // click in node
                -1 => int clickedNodeIdx;

                // Check if clicking on an on-screen Node
                for (int nodeIdx; nodeIdx < this.nodesOnScreen.size(); nodeIdx++) {
                    this.nodesOnScreen[nodeIdx] @=> Node node;

                    // Check if mouse is over this node's name box
                    node.mouseHoverNameBox(mouseWorldPos) => int nodeNameHover;
                    if (nodeNameHover) {
                        <<< "clicked on node name box", node.nodeID >>>;
                    }

                    // Check if mouse is over this node's content box
                    node.mouseHoverContentBox(mouseWorldPos) => int nodeContentHover;
                    if (nodeContentHover == 1) {
                        // Check if clicking on an Input/Output jack
                        node.mouseHoverOverJack(mouseWorldPos) => int jackIdx;
                        if (jackIdx != -1) {
                            node.jacks[jackIdx] @=> Jack jack;
                            @(node.posX() + jack.posX() * jack.scaX(), node.posY() + jack.posY() * jack.scaY()) => vec2 jackPos;

                            // Check if starting a new connection or completing a connection
                            if (this.openConnection == 0) {
                                // New connection needs to be from an Output jack
                                if (jack.ioType == IOType.OUTPUT) {
                                    <<< "Starting a new Connection" >>>;
                                    Connection newConnection(nodeIdx, jackIdx, jackPos, mouseWorldPos);
                                    newConnection @=> this.currOpenConnection;
                                    1 => this.openConnection;
                                }
                            } else {
                                // Completing a connection needs to be an Input jack
                                if (jack.ioType == IOType.INPUT) {
                                    // Output to input == complete the connection
                                    this.currOpenConnection.completeWire(nodeIdx, jackIdx, jackPos);

                                    // Connect output data to input data
                                    this.nodesOnScreen[this.currOpenConnection.outputNodeIdx] @=> Node outputNode;
                                    this.nodesOnScreen[this.currOpenConnection.inputNodeIdx] @=> Node inputNode;
                                    outputNode.jacks[this.currOpenConnection.outputNodeJackIdx].ugen @=> UGen ugen;
                                    inputNode.connect(ugen, this.currOpenConnection.inputNodeJackIdx);
                                    inputNode.jacks[this.currOpenConnection.inputNodeJackIdx].setUgen(ugen);

                                    // Add connection to connections list
                                    this.nodeConnections << this.currOpenConnection;

                                    // Remove open connection
                                    0 => this.openConnection;
                                    null => this.currOpenConnection;
                                } else {
                                    // Output to output == delete the connection
                                    this.currOpenConnection.deleteWire();
                                    0 => this.openConnection;
                                    null => this.currOpenConnection;
                                }
                            }
                        }

                        // Check if clicking on a menu
                        node.mouseHoverOverDropdownMenu(mouseWorldPos) => int dropdownMenuIdx;
                        if (dropdownMenuIdx != -1 && dropdownMenuEntryIdx == -1) {
                            <<< "Clicked on", node.menus[dropdownMenuIdx].menuID >>>;

                            // No existing menu opened
                            if (!this.menuOpen) {
                                node.menus[dropdownMenuIdx] @=> this.currMenu;
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
                }

                // If clicked outside of a node and a menu is open, close the menu
                if (clickedNodeIdx == -1 && this.menuOpen) {
                    this.currMenu.collapse();
                    0 => this.menuOpen;
                    null => this.currMenu;
                }
            }

            // Check if mouse left click is held down
            if (GWindow.mouseLeft()) {

                if (!this.nodeHeld) {
                    // Check if clicking on an on-screen Node
                    for (int nodeIdx; nodeIdx < this.nodesOnScreen.size(); nodeIdx++) {
                        this.nodesOnScreen[nodeIdx] @=> Node node;

                        // Check if mouse is over this node's name box
                        node.mouseHoverNameBox(mouseWorldPos) => int nodeNameHover;
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
                        if (this.currHeldNodeIdx == conn.outputNodeIdx) {
                            // Update Connection start (i.e. Output Jack position)
                            this.currHeldNode.jacks[conn.outputNodeJackIdx] @=> Jack jack;
                            @(this.currHeldNode.posX() + jack.posX() * jack.scaX(), this.currHeldNode.posY() + jack.posY() * jack.scaY()) => vec2 jackPos;
                            conn.updateWireStartPos(jackPos);
                        } else if (this.currHeldNodeIdx == conn.inputNodeIdx) {
                            // Update Connection end (i.e. Input Jack position)
                            this.currHeldNode.jacks[conn.inputNodeJackIdx] @=> Jack jack;
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
                    this.nodesOnScreen[this.currSelectedConnection.outputNodeIdx] @=> Node outputNode;
                    this.nodesOnScreen[this.currSelectedConnection.inputNodeIdx] @=> Node inputNode;
                    outputNode.jacks[this.currSelectedConnection.outputNodeJackIdx].ugen @=> UGen ugen;
                    inputNode.disconnect(ugen, this.currSelectedConnection.inputNodeJackIdx);
                    inputNode.jacks[this.currSelectedConnection.inputNodeJackIdx].removeUgen();

                    // Delete the wire
                    this.currSelectedConnection.deleteWire();

                    // Remove the connection from the connections list
                    this.nodeConnections.erase(this.currSelectedConnectionIdx);

                    // Unset selected connection variables
                    0 => this.connectionSelected;
                    -1 => this.currSelectedConnectionIdx;
                    null => this.currSelectedConnection;
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

            GG.nextFrame() => now;
        }
    }
}
