@import {"../ui/base.ck", "../ui/menu.ck", "../ui/textBox.ck"}
@import {"../base.ck", "../events.ck"}
@import "HashMap"


public class NodeType {
    // MIDI
    0 => static int MIDI_IN;
    1 => static int MIDI_OUT;

    // Audio
    10 => static int AUDIO_IN;
    11 => static int AUDIO_OUT;

    // OSC
    20 => static int OSC_IN;
    21 => static int OSC_OUT;

    // Sequencing
    400 => static int SEQUENCER;
    401 => static int TRANSPORT;
    402 => static int COMPOSE;
    403 => static int SCORE_PLAYER;

    // Effects
    50 => static int WAVEFOLDER;
    51 => static int DISTORTION;
    52 => static int DELAY;

    // Modifiers
    600 => static int SCALE;
    601 => static int ASR_ENV;
    602 => static int ADSR_ENV;
    603 => static int SCALE_TUNING;
    604 => static int EDO_TUNING;
}


public class Node extends ClickableGGen {
    string nodeID;
    1 => int nodeActive;
    Shred activeShreds[0];

    // Node Content Components
    NameBox @ nodeNameBox;
    OptionsBox @ nodeOptionsBox;
    IOModifierBox @ nodeInputsModifierBox;
    IOBox @ nodeInputsBox;
    IOModifierBox @ nodeOutputsModifierBox;
    IOBox @ nodeOutputsBox;
    IOModifierBox @ nodeButtonModifierBox;
    ButtonBox @ nodeButtonBox;
    VisibilityBox @ nodeVisibilityBox;

    // IO Options
    Enum inputTypes[];
    Enum outputTypes[];

    fun void setNodeID(string nodeID) {
        nodeID => this.nodeID;
    }

    fun void addShreds(Shred shreds[]) {
        for (Shred shred : shreds) {
            this.activeShreds << shred;
        }
    }

    fun void deactivateNode() {
        for (Shred shred : this.activeShreds) {
            <<< "Removing shred" >>>;
            // shred.exit();
            Machine.remove( shred.id() );
            me.yield();
        }

        // Get Rid of shreds in Input and Output IO Boxes
        if (this.nodeInputsBox != null) {
            for (Jack jack : this.nodeInputsBox.jacks) {
                if (jack.colorShred != null) Machine.remove(jack.colorShred.id());
            }
        }

        if (this.nodeOutputsBox != null) {
            for (Jack jack : this.nodeOutputsBox.jacks) {
                if (jack.colorShred != null) Machine.remove(jack.colorShred.id());
            }
        }

        0 => this.nodeActive;
    }

    fun int mouseOverNode(vec3 mouseWorldPos) {
        false => int mouseIsOver;

        this.mouseOverNameBox(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverOptionsBox(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverInputsModifierBox(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverInputsBox(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverOutputsModifierBox(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverOutputsBox(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverButtonModifierBox(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverButtonBox(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverVisibilityBox(mouseWorldPos) || mouseIsOver => mouseIsOver;

        return mouseIsOver;
    }

    fun int mouseOverNameBox(vec3 mouseWorldPos) {
        if (this.nodeNameBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeNameBox, this.nodeNameBox.contentBox]);
    }

    fun int mouseOverOptionsBox(vec3 mouseWorldPos) {
        if (this.nodeOptionsBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeOptionsBox, this.nodeOptionsBox.contentBox]);
    }

    fun int mouseOverInputsModifierBox(vec3 mouseWorldPos) {
        if (this.nodeInputsModifierBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeInputsModifierBox, this.nodeInputsModifierBox.contentBox]);
    }

    fun int mouseOverInputsBox(vec3 mouseWorldPos) {
        if (this.nodeInputsBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeInputsBox, this.nodeInputsBox.contentBox]);
    }

    fun int mouseOverOutputsModifierBox(vec3 mouseWorldPos) {
        if (this.nodeOutputsModifierBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeOutputsModifierBox, this.nodeOutputsModifierBox.contentBox]);
    }

    fun int mouseOverOutputsBox(vec3 mouseWorldPos) {
        if (this.nodeOutputsBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeOutputsBox, this.nodeOutputsBox.contentBox]);
    }

    fun int mouseOverButtonModifierBox(vec3 mouseWorldPos) {
        if (this.nodeButtonModifierBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeButtonModifierBox, this.nodeButtonModifierBox.contentBox]);
    }

    fun int mouseOverButtonBox(vec3 mouseWorldPos) {
        if (this.nodeButtonBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeButtonBox, this.nodeButtonBox.contentBox]);
    }

    fun int mouseOverVisibilityBox(vec3 mouseWorldPos) {
        if (this.nodeVisibilityBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeVisibilityBox, this.nodeVisibilityBox.contentBox]);
    }

    fun void hideInputsBox() {
        if (this.nodeInputsBox == null) return;

        if (this.nodeInputsModifierBox != null) {
            this.nodeInputsModifierBox --< this;
            0 => this.nodeInputsModifierBox.active;
        }

        this.nodeInputsBox --< this;
        0 => this.nodeInputsBox.active;
        this.updatePos();
    }

    fun void showInputsBox() {
        if (this.nodeInputsBox == null) return;

        if (this.nodeInputsModifierBox != null) {
            this.nodeInputsModifierBox --> this;
            1 => this.nodeInputsModifierBox.active;
        }

        this.nodeInputsBox --> this;
        1 => this.nodeInputsBox.active;
        this.updatePos();
    }

    fun void hideOutputsBox() {
        if (this.nodeOutputsBox == null) return;

        if (this.nodeOutputsModifierBox != null) {
            this.nodeOutputsModifierBox --< this;
            0 => this.nodeOutputsModifierBox.active;
        }

        this.nodeOutputsBox --< this;
        0 => this.nodeOutputsBox.active;
        this.updatePos();
    }

    fun void showOutputsBox() {
        if (this.nodeOutputsBox == null) return;

        if (this.nodeOutputsModifierBox != null) {
            this.nodeOutputsModifierBox --> this;
            1 => this.nodeOutputsModifierBox.active;
        }

        this.nodeOutputsBox --> this;
        1 => this.nodeOutputsBox.active;

        this.updatePos();
    }

    fun void hideOptionsBox() {
        if (this.nodeOptionsBox == null) return;

        this.nodeOptionsBox --< this;
        0 => this.nodeOptionsBox.active;
        this.updatePos();
    }

    fun void showOptionsBox() {
        if (this.nodeOptionsBox == null) return;

        this.nodeOptionsBox --> this;
        1 => this.nodeOptionsBox.active;
        this.updatePos();
    }

    fun void hideButtonBox() {
        if (this.nodeButtonBox == null) return;

        if (this.nodeButtonModifierBox != null) {
            this.nodeButtonModifierBox --< this;
            0 => this.nodeButtonModifierBox.active;
        }

        this.nodeButtonBox --< this;
        0 => this.nodeButtonBox.active;
        this.updatePos();
    }

    fun void showButtonBox() {
        if (this.nodeButtonBox == null) return;

        if (this.nodeButtonModifierBox != null) {
            this.nodeButtonModifierBox --> this;
            1 => this.nodeButtonModifierBox.active;
        }

        this.nodeButtonBox --> this;
        1 => this.nodeButtonBox.active;
        this.updatePos();
    }

    fun void selectNode() {
        if (this.nodeNameBox != null) {
            Color.RED => this.nodeNameBox.contentBox.color;
        }
    }

    fun void unselectNode() {
        if (this.nodeNameBox != null) {
            Color.BLACK => this.nodeNameBox.contentBox.color;
        }
    }

    fun vec2 inputJackPos(int jackIdx) {
        if (this.nodeInputsBox == null) <<< "Gonna have a nullpointer issue in inputJackPos..." >>>;

        this.posX() + (this.nodeInputsBox.posX() * this.scaX()) + (this.nodeInputsBox.jacks[jackIdx].posX() * this.scaX()) => float posX;

        if (!this.nodeInputsBox.active) {
            // Return the midpoint of the Node
            return @(posX, this.nodeMidpoint());
        }

        this.posY() + (this.nodeInputsBox.posY() * this.scaY()) + (this.nodeInputsBox.jacks[jackIdx].posY() * this.scaY()) => float posY;
        return @(posX, posY);
    }

    fun vec2 outputJackPos(int jackIdx) {
        if (this.nodeOutputsBox == null) <<< "Gonna have a nullpointer issue in outputJackPos..." >>>;

        this.posX() + (this.nodeOutputsBox.posX() * this.scaX()) + (this.nodeOutputsBox.jacks[jackIdx].posX() * this.scaX()) => float posX;

        if (!this.nodeOutputsBox.active) {
            // Return the midpoint of the Node
            return @(posX, this.nodeMidpoint());
        }

        this.posY() + (this.nodeOutputsBox.posY() * this.scaY()) + (this.nodeOutputsBox.jacks[jackIdx].posY() * this.scaY()) => float posY;

        return @(posX, posY);
    }

    fun ContentBox[] getContentBoxes() {
        [this.nodeNameBox] @=> ContentBox boxes[];

        if (this.nodeOptionsBox != null && this.nodeOptionsBox.active) {
            boxes << this.nodeOptionsBox;
        }

        if (this.nodeInputsModifierBox != null && this.nodeInputsModifierBox.active) {
            boxes << this.nodeInputsModifierBox;
        }

        if (this.nodeInputsBox != null && this.nodeInputsBox.active) {
            boxes << this.nodeInputsBox;
        }

        if (this.nodeOutputsModifierBox != null && this.nodeOutputsModifierBox.active) {
            boxes << this.nodeOutputsModifierBox;
        }

        if (this.nodeOutputsBox != null && this.nodeOutputsBox.active) {
            boxes << this.nodeOutputsBox;
        }

        if (this.nodeButtonModifierBox != null && this.nodeButtonModifierBox.active) {
            boxes << this.nodeButtonModifierBox;
        }

        if (this.nodeButtonBox != null && this.nodeButtonBox.active) {
            boxes << this.nodeButtonBox;
        }

        if (this.nodeVisibilityBox != null && this.nodeVisibilityBox.active) {
            boxes << this.nodeVisibilityBox;
        }

        return boxes;
    }

    fun float nodeMidpoint() {
        this.getContentBoxes() @=> ContentBox boxes[];

        if (boxes.size() == 0) return this.posY();

        float sum;
        for (ContentBox box : boxes) {
            sum + this.posY() + box.posY() * this.scaY() => sum;
        }

        return sum / boxes.size();
    }

    fun void updatePos() {
        this.getContentBoxes() @=> ContentBox boxes[];

        0 => int prevBoxIdx;
        1 => int currBoxIdx;

        ContentBox @ prevBox;
        ContentBox @ currBox;

        while (currBoxIdx < boxes.size()) {
            boxes[prevBoxIdx] @=> prevBox;
            boxes[currBoxIdx] @=> currBox;

            if (currBox != null) {
                prevBox.posY() - (prevBox.contentBox.scaY() / 2.) - (currBox.contentBox.scaY() / 2.) => currBox.posY;
                currBoxIdx => prevBoxIdx;
            }

            currBoxIdx++;
        }
    }

    fun float getValueFromUGen(UGen ugen) {
        // Value can be from a audio rate UGen (which uses last()),
        // a control rate UGen (which uses next()),
        // or an envelope UGen (which uses value())
        float value;
        if (Type.of(ugen).name() == Step.typeOf().name()) {
            (ugen$Step).next() => value;
        } else if (Type.of(ugen).name() == ADSR.typeOf().name() || Type.of(ugen).name() == Envelope.typeOf().name()) {
            (ugen$Envelope).value() => value;
        } else {
            ugen.last() => value;
        }

        return value;
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        <<< "ERROR: Override the Connect function for Child Nodes." >>>;
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        <<< "ERROR: Override the Disconnect function for Child Nodes." >>>;
    }

    fun void addJack(int ioType) {
        if (ioType == IOType.INPUT) {
            if (this.inputTypes == null) {
                <<< "ERROR: Trying to add an Input jack but inputTypes is not set" >>>;
                return;
            } else if (this.nodeInputsBox == null) {
                <<< "ERROR: Trying to add an Input jack but nodeInputsBox is not set" >>>;
                return;
            }
            this.nodeInputsBox.addJack(this.inputTypes);
        } else if (ioType == IOType.OUTPUT) {
            if (this.outputTypes == null) {
                <<< "ERROR: Trying to add an Input jack but outputTypes is not set" >>>;
                return;
            } else if (this.nodeOutputsBox == null) {
                <<< "ERROR: Trying to add an Input jack but nodeOutputsBox is not set" >>>;
                return;
            }
            this.nodeOutputsBox.addJack(this.outputTypes);
        } else {
            <<< "ERROR: Unknown IOType with value:", ioType >>>;
        }
        this.updatePos();
    }

    fun void removeJack(int ioType) {
        if (ioType == IOType.INPUT) {
            if (this.nodeInputsBox == null) {
                <<< "ERROR: Trying to remove an Input jack but nodeInputsBox is not set" >>>;
                return;
            }
            this.nodeInputsBox.removeJack();
        } else if (ioType == IOType.OUTPUT) {
            if (this.nodeOutputsBox == null) {
                <<< "ERROR: Trying to remove an Input jack but nodeOutputsBox is not set" >>>;
                return;
            }
            this.nodeOutputsBox.removeJack();
        } else {
            <<< "ERROR: Unknown IOType with value:", ioType >>>;
        }
        this.updatePos();
    }

    fun void addButton() {
        <<< "ERROR: Override the addButton function for Child Nodes" >>>;
    }

    fun void removeButton() {
        <<< "ERROR: Override the removeButton function for Child Nodes" >>>;
    }

    fun void handleButtonPress(int buttonIdx) {
        <<< "ERROR: Override the handleButtonPress function for Child Nodes" >>>;
    }

    fun HashMap serialize() {
        <<< "ERROR: Override the serialize function for Child Nodes" >>>;
        return null;
    }

    fun void serialize(HashMap data) {
        // TODO: when `super()` is supported, replace this function with
        // Node.serialize() which just returns the base HashMap, which the
        // child node can add to.
        data.set("nodeClass", Type.of(this).name());
        data.set("nodeID", this.nodeID);
        data.set("posX", this.posX());
        data.set("posY", this.posY());
        data.set("posZ", this.posZ());

        // Handle visibility
        if (this.nodeOptionsBox != null) {
            data.set("optionsActive", this.nodeOptionsBox.active);
        }

        if (this.nodeInputsBox != null) {
            data.set("inputsActive", this.nodeInputsBox.active);
        }

        if (this.nodeOutputsBox != null) {
            data.set("outputsActive", this.nodeOutputsBox.active);
        }
    }
}


public class IOType {
    0 => static int INPUT;
    1 => static int OUTPUT;

    fun static string toString(int ioType) {
        if (ioType == IOType.INPUT) return "In";
        if (ioType == IOType.OUTPUT) return "Out";

        return "Null";
    }
}


public class Connection extends GGen {
    Node @ outputNode;
    int outputNodeJackIdx;
    vec2 outputJackPos;

    Node @ inputNode;
    int inputNodeJackIdx;
    vec2 inputJackPos;

    GLines wire;

    fun @construct(Node @ outputNode, int outputNodeJackIdx, vec2 outputJackPos, vec3 mouseWorldPos) {
        outputNode @=> this.outputNode;
        outputNodeJackIdx => this.outputNodeJackIdx;
        outputJackPos => this.outputJackPos;

        // Position
        0.101 => this.wire.posZ;

        // Handle Lines
        [this.outputJackPos, @(mouseWorldPos.x, mouseWorldPos.y)] => this.wire.positions;
        0.05 => this.wire.width;

        // Color
        Color.RED => this.wire.color;

        // Names
        "Open Connection: Node" + this.outputNode.nodeID + " Jack" + this.outputNodeJackIdx => this.name;
        "Wire" => this.wire.name;

        // Connections
        this.wire --> this --> GG.scene();
    }

    fun void completeWire(Node @ inputNode, int inputNodeJackIdx, vec2 inputJackPos) {
        inputNode @=> this.inputNode;
        inputNodeJackIdx => this.inputNodeJackIdx;
        inputJackPos => this.inputJackPos;
        "Completed Connection: Node" + this.outputNode.nodeID + " Jack" + this.outputNodeJackIdx + " -> Node" + this.inputNode.nodeID + " Jack" + this.inputNodeJackIdx => this.name;

        [this.outputJackPos, this.inputJackPos] => this.wire.positions;

        // Set Color
        Color.BLACK => this.wire.color;
    }

    fun void updateWire(vec3 mouseWorldPos) {
        [this.outputJackPos, @(mouseWorldPos.x, mouseWorldPos.y)] => this.wire.positions;
    }

    fun void updateWireStartPos(vec2 outputJackPos) {
        outputJackPos => this.outputJackPos;
        [this.outputJackPos, this.inputJackPos] => this.wire.positions;
    }

    fun void updateWireEndPos(vec2 inputJackPos) {
        inputJackPos => this.inputJackPos;
        [this.outputJackPos, this.inputJackPos] => this.wire.positions;
    }

    fun void deleteWire() {
        this --< GG.scene();
    }

    fun int mouseOverWire(vec3 mouseWorldPos) {
        @(this.inputJackPos.x - this.outputJackPos.x, this.inputJackPos.y - this.outputJackPos.y) => vec2 d;  // vector along line
        @(mouseWorldPos.x - this.outputJackPos.x, mouseWorldPos.y - this.outputJackPos.y) => vec2 m; // Vector from start to mouse
        d.dot(d) => float lenSq; // squared length of the line

        // Project m onto d
        m.dot(d) / lenSq => float t;
        if (t < 0.) 0. => t;
        if (t > 1.) 1. => t;

        // Find closest point on the line segment to the mouse
        this.outputJackPos + (d * t) => vec2 closest;

        // Distance from mouse to closest point
        (@(mouseWorldPos.x, mouseWorldPos.y) - closest) => vec2 mouseToClosest;
        Math.sqrt(mouseToClosest.dot(mouseToClosest)) => float dist;

        return dist <= this.wire.width() / 2.;
    }

    fun void selectWire() {
        Color.RED => this.wire.color;
    }

    fun void unselectWire() {
        Color.BLACK => this.wire.color;
    }

    fun HashMap serialize() {
        HashMap data;
        data.set("outputNodeID", this.outputNode.nodeID);
        data.set("outputNodeJackIdx", this.outputNodeJackIdx);
        data.set("outputJackPosX", this.outputJackPos.x);
        data.set("outputJackPosY", this.outputJackPos.y);

        data.set("inputNodeID", this.inputNode.nodeID);
        data.set("inputNodeJackIdx", this.inputNodeJackIdx);
        data.set("inputJackPosX", this.inputJackPos.x);
        data.set("inputJackPosY", this.inputJackPos.y);

        return data;
    }
}


public class Jack extends GGen {
    GTorus border;
    GCylinder jack;

    int ioType;
    int isConnected;
    UGen @ ugen;

    Shred @ colorShred;

    fun @construct(int jackID, int ioType) {
        // Member variables
        ioType => this.ioType;

        // Position
        -0.25 => this.jack.posZ;

        // Scale
        @(4.0, 1., 4.0) => this.jack.sca;
        @(0.25, 0.25, 1.) => this.sca;

        // Rotation
        Math.PI / 2 => this.jack.rotX;

        // Color
        Color.DARKGRAY => this.border.color;
        Color.BLACK => this.jack.color;

        // Names
        "IO Jack " + jackID => this.name;
        "Jack Border" => this.border.name;
        "Jack Hole" => this.jack.name;

        // Connections
        this.jack --> this.border --> this;

        // Handle jack color
        spork ~ this.setColor() @=> this.colorShred;
    }

    fun void setUgen(UGen ugen) {
        1 => this.isConnected;
        ugen @=> this.ugen;
    }

    fun void removeUgen() {
        // TODO: set ugen to null here?
        Color.BLACK => this.jack.color;
        0 => this.isConnected;
    }

    fun void setColor() {
        while (true) {
            if (!this.isConnected || this.ugen == null) {
                GG.nextFrame() => now;
                continue;
            }

            0. => float voltage;
            if (Type.of(this.ugen).name() == "Step") {
                this.ugen $ Step @=> Step step;
                step.next() => voltage;
            } else {
                this.ugen.last() => voltage;
            }

            0. => float hue;
            1. => float saturation;
            if (voltage < 0.) 240. => hue;

            Std.scalef(Std.fabs(voltage), 0., 1., 0., 1.) => float value;
            Std.clampf(value, 0., 1.) => value;

            Color.hsv2rgb(@(hue, saturation, value)) * 3 => this.jack.color;

            GG.nextFrame() => now;
        }
    }
}


public class ContentBox extends GGen {
    GCube contentBox;
    1 => int active;
}


public class NameBox extends ContentBox {
    GText nodeName;

    fun @construct(string name,float xScale) {
        // Text
        name => this.nodeName.text;

        // Position
        0.101 => this.nodeName.posZ;

        // Scale
        @(0.25, 0.25, 0.25) => this.nodeName.sca;
        @(xScale, 1., 0.2) => this.contentBox.sca;

        // Color
        @(3., 3., 3., 1.) => this.nodeName.color;
        Color.BLACK => this.contentBox.color;

        // Names
        "GText Name" => this.nodeName.name;
        "GCube Content Box" => this.contentBox.name;
        "Name Box " => this.name;

        // Connections
        this.nodeName --> this;
        this.contentBox --> this;
    }
}


public class IOBox extends ContentBox {
    // Contents
    Jack jacks[0];
    DropdownMenu menus[0];
    NumberEntryBox numberBoxes[0];

    // Data handling
    Step outs[0];
    int dataMap[0];

    // IO Type
    int ioType;
    int xPosModifier;

    // Jacks
    int numJacks;

    // Menus
    int hasMenus;
    DropdownMenu @ openMenu;
    int includeNumberEntry[];

    fun @construct(int numJacks, int ioType, string parentNodeID, float xScale) {
        // Create an IO box without menus
        IOBox(numJacks, null, ioType, parentNodeID, xScale);
    }

    fun @construct(int numStartJacks, Enum ioMenuEntries[], int ioType, string parentNodeID, float xScale) {
        // Create an IO box with menus and without a number entry box
        int includeNumberEntry[0];
        if (ioMenuEntries != null) {
            for (int idx; idx < ioMenuEntries.size(); idx++) {
                includeNumberEntry << 0;
            }
        }

        IOBox(numStartJacks, ioMenuEntries, includeNumberEntry, ioType, parentNodeID, xScale);
    }


    fun @construct(int numStartJacks, Enum ioMenuEntries[], int includeNumberEntry[], int ioType, string parentNodeID, float xScale) {
        // Member variables
        ioType => this.ioType;
        numStartJacks => this.numJacks;
        ioMenuEntries != null => this.hasMenus;
        includeNumberEntry @=> this.includeNumberEntry;

        // Scale
        @(xScale, numStartJacks, 0.2) => this.contentBox.sca;

        // Color
        Color.GRAY => this.contentBox.color;

        // Initialize data map
        if (ioMenuEntries != null) {
            for (int idx; idx < ioMenuEntries.size(); idx++) {
                this.dataMap << -1;
            }
        }

        // Position handling for Jacks Only vs. Jacks and Menus
        0 => this.xPosModifier;
        if (this.hasMenus) {
            1 => this.xPosModifier;
            if (ioType == IOType.INPUT) {
                -1 => this.xPosModifier;
            }
        }

        // Jacks and Menus
        (this.contentBox.scaY() - 1) / 2. => float startPosY;
        for (int idx; idx < numStartJacks; idx++) {
            Jack jack(idx, ioType);
            Step out(0.);

            // Jack Position
            1.25 * this.xPosModifier => jack.posX;
            startPosY + (idx * -1) => jack.posY;

            // Add jack to list
            this.jacks << jack;
            this.outs << out;

            // Connect jack to IO box
            jack --> this;

            if (this.hasMenus) {
                DropdownMenu menu(ioMenuEntries, parentNodeID, idx);

                // Menus position
                -0.75 * this.xPosModifier => menu.posX;
                startPosY + (idx * -1) => menu.posY;
                0.1 => menu.posZ;

                // Add menu to list
                this.menus << menu;

                // Connect menu to IO box
                menu --> this;

                // Add number entry box for each menu
                NumberEntryBox numberBox(3, idx);
                -0.27 * this.xPosModifier => numberBox.posX;
                startPosY + (idx * -1) => numberBox.posY;
                0.1 => numberBox.posZ;
                this.numberBoxes << numberBox;
            }
        }

        // Names
        "IOBox " + this.ioType => this.name;
        "Content Box" => this.contentBox.name;

        // Connect boxes to IO box
        this.contentBox --> this;
    }

    fun void setInput(Enum dataType, int jackIdx) {
        if (this.ioType != IOType.INPUT) {
            <<< "ERROR: Trying to set an input on an Output box." >>>;
            return;
        } else if (jackIdx > this.jacks.size() || jackIdx > this.menus.size()) {
            <<< "ERROR: Jack idx", jackIdx, "greater than Jack/Menu size of", this.jacks.size() >>>;
            return;
        }

        // Update the Menu Entry
        this.menus[jackIdx].updateSelectedEntry(dataType.id);
        this.setDataTypeMapping(dataType, jackIdx);
    }

    fun void setOutput(Enum dataType, int jackIdx, UGen out) {
        if (this.ioType != IOType.OUTPUT) {
            <<< "ERROR: Trying to set an output on an Input box." >>>;
            return;
        } else if (jackIdx > this.jacks.size() || jackIdx > this.menus.size()) {
            <<< "ERROR: Jack idx", jackIdx, "greater than Jack/Menu size of", this.jacks.size() >>>;
            return;
        }

        // Update the Menu Entry
        this.menus[jackIdx].updateSelectedEntry(dataType.id);

        // Set out UGen
        this.jacks[jackIdx].setUgen(out);
    }

    fun void setDataTypeMapping(Enum dataType, int jackIdx) {
        if (jackIdx >= this.jacks.size() || jackIdx < 0) {
            <<< "ERROR: Jack index out of bounds" >>>;
            return;
        }

        dataType.id => this.dataMap[jackIdx];
    }

    fun int getDataTypeMapping(int jackIdx) {
        if (jackIdx >= this.jacks.size() || jackIdx < 0) {
            <<< "ERROR: Jack index out of bounds" >>>;
            return -1;
        }

        return this.dataMap[jackIdx];
    }

    fun void removeDataTypeMapping(int jackIdx) {
        if (jackIdx >= this.jacks.size() || jackIdx < 0) {
            <<< "ERROR: Jack index out of bounds" >>>;
            return;
        }

        -1 => this.dataMap[jackIdx];
    }

    fun UGen getJackUGen(int jackIdx) {
        if (jackIdx >= this.jacks.size() || jackIdx < 0) {
            <<< "ERROR: Jack index", jackIdx, "is out of bounds for Jack Length", this.jacks.size() >>>;
            return null;
        }

        return this.jacks[jackIdx].ugen;
    }

    fun int hasNumberBox(int ioEntryIdx) {
        if (ioEntryIdx >= this.dataMap.size() || ioEntryIdx < 0) {
            <<< "ERROR: IO entry index out of bounds" >>>;
            return false;
        }

        return this.includeNumberEntry[ioEntryIdx];
    }

    fun void showNumberBox(int jackIdx) {
        if (jackIdx >= this.jacks.size() || jackIdx < 0) {
            <<< "ERROR: Jack index out of bounds" >>>;
            return;
        }

        // Check if already active
        if (this.numberBoxes[jackIdx].active) return;

        // Update menu scale and position
        this.menus[jackIdx].setSelectedScale(1., 0.5);
        -1.23 * this.xPosModifier => this.menus[jackIdx].posX;

        this.numberBoxes[jackIdx] --> this;
        1 => this.numberBoxes[jackIdx].active;
    }

    fun void hideNumberBox(int jackIdx) {
        if (jackIdx >= this.jacks.size() || jackIdx < 0) {
            <<< "ERROR: Jack index out of bounds" >>>;
            return;
        }

        // Check if already inactive
        if (!this.numberBoxes[jackIdx].active) return;

        // Update menu scale and position
        this.menus[jackIdx].setSelectedScale(2., 0.5);
        -0.75 * this.xPosModifier => this.menus[jackIdx].posX;

        this.numberBoxes[jackIdx] --< this;
        0 => this.numberBoxes[jackIdx].active;
    }

    fun void setNumberBoxUpdateEvent(UpdateNumberEntryBoxEvent updateEvent) {
        for (int idx; idx < this.numberBoxes.size(); idx++) {
            this.numberBoxes[idx] @=> NumberEntryBox numberBox;
            numberBox.setUpdateEvent(updateEvent);
        }
    }

    fun void addJack(Enum menuSelections[]) {
        this.numJacks => int jackIdx;
        Jack jack(jackIdx, IOType.OUTPUT);
        Step out(0.);

        // Update numJacks
        this.numJacks++;

        // Update contentBox scale
        this.numJacks => this.contentBox.scaY;

        // Jack position
        1.25 * this.xPosModifier => jack.posX;

        // Add objects to lists
        this.jacks << jack;
        this.outs << out;

        // Jack Connection
        jack --> this;

        // Handle Menus
        if (this.hasMenus) {
            DropdownMenu jackMenu(menuSelections, jackIdx);

            // Menu position
            -0.75 * this.xPosModifier => jackMenu.posX;
            0.1 => jackMenu.posZ;

            // Add menu to list
            this.menus << jackMenu;

            // Connect menu to IO box
            jackMenu --> this;

            // Add number entry box for each menu
            NumberEntryBox numberBox(3, jackIdx);
            -0.27 * this.xPosModifier => numberBox.posX;
            0.1 => numberBox.posZ;
            this.numberBoxes << numberBox;
        }

        // Update Jack and Menu Y Pos
        this.updateJackandMenuYPos();
    }

    fun Enum removeJack() {
        if (this.numJacks == 1) return null;

        this.jacks[-1] @=> Jack jack;
        this.menus[-1] @=> DropdownMenu jackMenu;

        // Update numJacks
        this.numJacks--;

        // Update content box scale
        this.numJacks => this.contentBox.scaY;

        // Remove connections
        jack --< this;
        jackMenu --< this;

        // Remove number box
        this.hideNumberBox(this.numJacks);

        // Remove objects from lists
        this.jacks.popBack();
        this.menus.popBack();
        this.outs.popBack();
        this.numberBoxes.popBack();

        // Update Jack and Menu Y Pos
        this.updateJackandMenuYPos();

        // Return the removed menu selection
        // Parent node will handle the removal of the output data type mapping
        jackMenu.getSelectedEntry() @=> Enum menuSelection;
        return menuSelection;
    }

    fun void updateJackandMenuYPos() {
        (this.contentBox.scaY() - 1) / 2. => float startPosY;

        for (int idx; idx < this.jacks.size(); idx++) {
            this.jacks[idx] @=> Jack jack;
            startPosY + (idx * -1) => jack.posY;
        }

        for (int idx; idx < this.menus.size(); idx++) {
            this.menus[idx] @=> DropdownMenu menu;
            startPosY + (idx * -1) => menu.posY;
        }

        for (int idx; idx < this.numberBoxes.size(); idx++) {
            this.numberBoxes[idx] @=> NumberEntryBox numberBox;
            startPosY + (idx * -1) => numberBox.posY;
        }
    }

    fun int mouseOverJack(vec3 mouseWorldPos) {
        this.parent()$Node @=> Node parentNode;
        -1 => int jackIdx;

        for (int idx; idx < this.jacks.size(); idx++) {
            this.jacks[idx] @=> Jack jack;

            if (parentNode.mouseOverBox(mouseWorldPos, [this, jack])) {
                idx => jackIdx;
                break;
            }
        }

        return jackIdx;
    }

    fun int mouseOverDropdownMenu(vec3 mouseWorldPos) {
        this.parent()$Node @=> Node parentNode;
        -1 => int dropdownMenuIdx;

        for (int idx; idx < this.menus.size(); idx++) {
            this.menus[idx] @=> DropdownMenu menu;

            if (parentNode.mouseOverBox(mouseWorldPos, [this, menu, menu.selectedBox.box])) {
                idx => dropdownMenuIdx;
                break;
            }
        }

        return dropdownMenuIdx;
    }

    fun int mouseOverNumberBox(vec3 mouseWorldPos) {
        this.parent()$Node @=> Node parentNode;
        -1 => int numberBoxIdx;

        for (int idx; idx < this.numberBoxes.size(); idx++) {
            this.numberBoxes[idx] @=> NumberEntryBox numberBox;

            if (parentNode.mouseOverBox(mouseWorldPos, [this, numberBox, numberBox.box])) {
                // Only return Idx if number box is active
                // Still break because it would be a click on an inactive number box, just return -1
                if (numberBox.active) idx => numberBoxIdx;
                break;
            }
        }

        return numberBoxIdx;
    }
}


public class IOModifierBox extends ContentBox {
    BorderedBox @ addBox;
    BorderedBox @ removeBox;

    1 => static int ADD;
    -1 => static int REMOVE;

    fun @construct(float xScale) {
        new BorderedBox("+", 0.5, 0.5) @=> this.addBox;
        new BorderedBox("-", 0.5, 0.5) @=> this.removeBox;

        // Position
        0.6 => this.addBox.posX;
        -0.6 => this.removeBox.posX;

        // Scale
        @(xScale, 1., 0.2) => this.contentBox.sca;

        // Color
        Color.GRAY => this.contentBox.color;

        // Names
        "IO Modifier Box" => this.name;
        "Add Bordered Box" => this.addBox.name;
        "Remove Bordered Box" => this.removeBox.name;

        // Connections
        this.contentBox --> this;
        this.addBox --> this;
        this.removeBox --> this;
    }

    fun int mouseOverModifiers(vec3 mouseWorldPos) {
        this.parent()$Node @=> Node parentNode;

        // Check AddBox
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.addBox, this.addBox.box])) return this.ADD;

        // Check RemoveBox
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.removeBox, this.removeBox.box])) return this.REMOVE;

        return 0;
    }
}


public class OptionsBox extends ContentBox {
    GText optionNames[0];
    int numOptions;
    int menuOpen;
    int menuSelected;
    int entryBoxSelected;
    int textBoxSelected;

    DropdownMenu @ selectedMenu;
    NumberEntryBox @ selectedEntryBox;
    TextEntryBox @ selectedTextBox;

    fun @construct(string optionNames[], float xScale) {
        optionNames.size() => this.numOptions;

        // Start Position
        (this.numOptions - 1) / 2. => float startPosY;

        for (int idx; idx < optionNames.size(); idx++) {
            GText text;
            optionNames[idx] => text.text;
            @(3., 3., 3., 1.) => text.color;
            @(0., 0.5) => text.controlPoints;

            @(-1 * ((xScale - (xScale * 0.2)) / 2.), startPosY + (idx * -1), 0.201) => text.pos;
            @(0.25, 0.25, 0.25) => text.sca;
            this.optionNames << text;

            "GText " + optionNames[idx] => text.name;
            text --> this;
        }

        // Scale
        @(xScale, this.numOptions, 0.2) => this.contentBox.sca;

        // Color
        Color.GRAY => this.contentBox.color;

        // Name
        "OptionsBox Content Box" => this.contentBox.name;
        "Node Options Box" => this.name;

        // Connections
        this.contentBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        <<< "ERROR: Override the handleMouseOver function for Child Nodes" >>>;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        <<< "ERROR: Override the handleMouseLeftDown function for Child Nodes" >>>;
        return false;
    }

    fun void handleNotClickedOn() {
        <<< "ERROR: Override the handleNotClickedOn function for Child Nodes" >>>;
    }
}


public class ButtonBox extends ContentBox {
    // Contents
    Button buttons[0];

    fun @construct(int numStartButtons, float xScale) {
        // Scale
        @(xScale, numStartButtons, 0.2) => this.contentBox.sca;

        // Color
        Color.GRAY => this.contentBox.color;

        // Initialize buttons
        (this.contentBox.scaY() - 1) / 2. => float startPosY;
        for (int idx; idx < numStartButtons; idx++) {
            Button button(Std.itoa(idx + 1), 0.5 * xScale, 0.5);
            startPosY + (idx * -1) => button.posY;

            button --> this;
            this.buttons << button;
        }

        // Names
        "ButtonsBox" => this.name;
        "Content Box" => this.contentBox.name;

        // Connections
        this.contentBox --> this;
    }

    fun void addButton() {
        // Update contentBox scale
        this.buttons.size() + 1 => this.contentBox.scaY;

        // Add and connect new button
        Button button(Std.itoa(this.buttons.size() + 1), 0.5 * this.contentBox.scaX(), 0.5);
        button --> this;
        this.buttons << button;

        // Reposition Buttons
        this.updateButtonPos();

        // Update position of content boxes
        (this.parent()$Node).updatePos();
    }

    fun void removeButton() {
        if (this.buttons.size() == 1) return;

        // Remove button from screen
        this.buttons[-1] @=> Button button;
        this.buttons.popBack();
        button --< this;

        // Update contentBox scale
        this.buttons.size() => this.contentBox.scaY;

        // Reposition Buttons
        this.updateButtonPos();

        // Update position of content boxes
        (this.parent()$Node).updatePos();
    }

    fun void updateButtonPos() {
        (this.contentBox.scaY() - 1) / 2. => float startPosY;

        for (int idx; idx < this.buttons.size(); idx++) {
            this.buttons[idx] @=> Button button;
            startPosY + (idx * -1) => button.posY;
        }
    }

    fun int mouseOverButtons(vec3 mouseWorldPos) {
        this.parent()$Node @=> Node parentNode;

        // Go through each button
        for (int idx; idx < this.buttons.size(); idx++) {
            this.buttons[idx] @=> Button currButton;
            if (parentNode.mouseOverBox(mouseWorldPos, [this, currButton, currButton.box])) return idx;
        }

        return -1;
    }
}


public class VisibilityBox extends ContentBox {
    BorderedBox @ optionsBox;
    BorderedBox @ inputsBox;
    BorderedBox @ outputsBox;

    1 => static int OPTIONS_BOX;
    2 => static int INPUTS_BOX;
    3 => static int OUTPUTS_BOX;

    fun @construct(float xScale) {
        new BorderedBox("Opts", 1., 0.5) @=> this.optionsBox;
        new BorderedBox("Ins", 1., 0.5) @=> this.inputsBox;
        new BorderedBox("Outs", 1., 0.5) @=> this.outputsBox;

        // Position
        @(1.2, 0., 0.1) => this.optionsBox.pos;
        @(0., 0., 0.1) => this.outputsBox.pos;
        @(-1.2, 0., 0.1) => this.inputsBox.pos;

        // Scale
        @(xScale, 1.0, 0.2) => this.contentBox.sca;

        // Color
        Color.BLACK => this.contentBox.color;

        // Names
        "Visibility Box" => this.name;
        "Options Button Box" => this.optionsBox.name;
        "IO Button Box" => this.inputsBox.name;

        // Connections
        this.contentBox --> this;
        this.optionsBox --> this;
        this.inputsBox --> this;
        this.outputsBox --> this;
    }

    fun int mouseHoverModifiers(vec3 mouseWorldPos) {
        this.parent()$Node @=> Node parentNode;

        // Check optionsBox
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.optionsBox, this.optionsBox.box])) return this.OPTIONS_BOX;

        // Check inputsBox
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.inputsBox, this.inputsBox.box])) return this.INPUTS_BOX;

        // Check outputsBox
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.outputsBox, this.outputsBox.box])) return this.OUTPUTS_BOX;

        return 0;
    }
}
