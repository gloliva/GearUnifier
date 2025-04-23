// Imports
@import "base.ck"


public class NodeManager {
    // Nodes
    Node nodesOnScreen[0];
    int numNodes;

    // Connections
    Connection nodeConnections[0];
    Connection @ currConnection;
    int openConnection;

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

                for (int nodeIdx; nodeIdx < this.nodesOnScreen.size(); nodeIdx++) {
                    this.nodesOnScreen[nodeIdx] @=> Node node;
                    node.mouseHoverContentBox(mousePos) => int nodeHover;

                    // Check if mouse is over this node
                    if (nodeHover == 1) {
                        // Check if mouse is over an Input/Output jack
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
                            // Check if Jack is input or output
                            <<< "Hovered over node:", node.nodeID, "at position", mousePos.x, mousePos.y  >>>;
                            <<< "Hovered over jack:", node.jacks[jackIdx].name() >>>;
                        }

                        node.mouseHoverOverDropdownMenu(mousePos) => int dropdownMenuIdx;
                        if (dropdownMenuIdx != -1) {
                            // TODO: do stuff here
                        }
                    }
                }
            }

            // Handle moving wire for open connection
            if (this.openConnection == 1) {
                this.currConnection.updateWire(mousePos);
            }

            GG.nextFrame() => now;
        }
    }
}
