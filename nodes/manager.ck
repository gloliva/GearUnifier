// Imports
@import "../ui/menu.ck"
@import "base.ck"
@import "midi.ck"


public class NodeManager {
    // Nodes
    Node nodesOnScreen[0];
    int numNodes;

    // Connections
    Connection nodeConnections[0];
    Connection @ currConnection;
    int openConnection;

    // Menus
    int openMenu;
    DropdownMenu @ currMenu;

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
        while (true) {
            GG.camera().screenCoordToWorldPos(GWindow.mousePos(), 1) => vec3 mousePos;

            // Mouse Click Down
            if (GWindow.mouseLeftDown() == 1) {

                // If a menu is open, check if clicking on a menu entry item
                // We check this here before checking nodes, because a dropdown menu
                // can extend beyond the Node's Y position, which would skip any processing
                // handled in the Node conditionals
                -1 => int dropdownMenuEntryIdx;
                if (this.openMenu) this.currMenu.mouseHoverEntry(mousePos) => dropdownMenuEntryIdx;

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
                    0 => this.openMenu;
                    null => this.currMenu;
                }

                // click in node
                -1 => int clickedNodeIdx;

                // Check if clicking on an on-screen Node
                for (int nodeIdx; nodeIdx < this.nodesOnScreen.size(); nodeIdx++) {
                    this.nodesOnScreen[nodeIdx] @=> Node node;
                    node.mouseHoverContentBox(mousePos) => int nodeHover;

                    // Check if mouse is over this node
                    if (nodeHover == 1) {
                        // Check if clicking on an Input/Output jack
                        node.mouseHoverOverJack(mousePos) => int jackIdx;
                        if (jackIdx != -1) {
                            node.jacks[jackIdx] @=> Jack jack;
                            @(node.posX() + jack.posX() * jack.scaX(), node.posY() + jack.posY() * jack.scaY()) => vec2 jackPos;

                            // Check if starting a new connection or completing a connection
                            if (this.openConnection == 0) {
                                // New connection needs to be from an Output jack
                                if (jack.ioType == IOType.OUTPUT) {
                                    <<< "Starting a new Connection" >>>;
                                    Connection newConnection(nodeIdx, jackIdx, jackPos, mousePos);
                                    newConnection @=> this.currConnection;
                                    1 => this.openConnection;
                                }
                            } else {
                                // Completing a connection needs to be an Input jack
                                if (jack.ioType == IOType.INPUT) {
                                    // Output to input == complete the connection
                                    this.currConnection.completeWire(nodeIdx, jackIdx, jackPos);

                                    // Connect output data to input data
                                    this.nodesOnScreen[this.currConnection.outputNodeIdx] @=> Node outputNode;
                                    this.nodesOnScreen[this.currConnection.inputNodeIdx] @=> Node inputNode;
                                    outputNode.jacks[this.currConnection.outputNodeJackIdx].ugen @=> UGen ugen;
                                    inputNode.connect(ugen, this.currConnection.inputNodeJackIdx);
                                    inputNode.jacks[this.currConnection.inputNodeJackIdx].setUgen(ugen);

                                    // Open the connection
                                    0 => this.openConnection;
                                    null => this.currConnection;
                                } else {
                                    // Output to output == delete the connection
                                    this.currConnection.deleteWire();
                                    0 => this.openConnection;
                                    null => this.currConnection;
                                }
                            }
                        }

                        // Check if clicking on a menu
                        node.mouseHoverOverDropdownMenu(mousePos) => int dropdownMenuIdx;
                        if (dropdownMenuIdx != -1 && dropdownMenuEntryIdx == -1) {
                            <<< "Clicked on", node.menus[dropdownMenuIdx].menuID >>>;

                            // No existing menu opened
                            if (!this.openMenu) {
                                node.menus[dropdownMenuIdx] @=> this.currMenu;
                                this.currMenu.expand();
                                1 => this.openMenu;
                            }
                        // Close active menu if Menu is open and click outside of menu
                        } else if (dropdownMenuIdx == -1 && dropdownMenuEntryIdx == -1 && this.openMenu) {
                            this.currMenu.collapse();
                            0 => this.openMenu;
                            null => this.currMenu;
                        }

                        // Found the node that was clicked on, can exit early
                        nodeIdx => clickedNodeIdx;
                        break;
                    }
                }

                // If clicked outside of a node and a menu is open, close the menu
                if (clickedNodeIdx == -1 && this.openMenu) {
                    this.currMenu.collapse();
                    0 => this.openMenu;
                    null => this.currMenu;
                }
            }

            // Handle moving wire for open connection
            if (this.openConnection == 1) {
                this.currConnection.updateWire(mousePos);
            }

            // Highlight menu item if mouse hovers over it
            if (this.openMenu) {
                this.currMenu.mouseHoverEntry(mousePos) => int hoveredMenuEntryIdx;
                this.currMenu.highlightHoveredEntry(hoveredMenuEntryIdx);
            }

            GG.nextFrame() => now;
        }
    }
}
