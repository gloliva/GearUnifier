@import "../ui/base.ck"
@import "../ui/menu.ck"


public class NodeType {
    0 => static int MIDI_IN;
    1 => static int MIDI_OUT;
    2 => static int AUDIO_IN;
    3 => static int AUDIO_OUT;
}


public class Node extends GGen {
    string nodeID;

    NameBox @ nodeNameBox;
    OptionsBox @ nodeOptionsBox;
    IOModifierBox @ nodeInputsModifierBox;
    IOBox @ nodeInputsBox;
    IOModifierBox @ nodeOutputsModifierBox;
    IOBox @ nodeOutputsBox;
    VisibilityBox @ nodeVisibilityBox;

    fun int mouseOverBox(vec3 mouseWorldPos, GGen box) {
        this.posX() + box.posX() * this.scaX() => float centerX;
        this.posY() + box.posY() * this.scaY() => float centerY;
        (box.scaX() * this.scaX()) / 2.0 => float halfW;
        (box.scaY() * this.scaY()) / 2.0 => float halfH;

        if (
            mouseWorldPos.x >= centerX - halfW && mouseWorldPos.x <= centerX + halfW
            && mouseWorldPos.y >= centerY - halfH && mouseWorldPos.y <= centerY + halfH
        ) {
            return true;
        }

        return false;
    }

    fun int mouseOverBox(vec3 mouseWorldPos, GGen boxes[]) {
        this.posX() => float centerX;
        this.posY() => float centerY;
        this.scaX() => float halfW;
        this.scaY() => float halfH;

        for (GGen box : boxes) {
            centerX + (box.posX() * this.scaX()) => centerX;
            centerY + (box.posY() * this.scaY()) => centerY;

            halfW * box.scaX() => halfW;
            halfH * box.scaY() => halfH;
        }

        halfW / 2. => halfW;
        halfH / 2. => halfH;

        if (
            mouseWorldPos.x >= centerX - halfW && mouseWorldPos.x <= centerX + halfW
            && mouseWorldPos.y >= centerY - halfH && mouseWorldPos.y <= centerY + halfH
        ) {
            return true;
        }

        return false;
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

    fun int mouseOverVisibilityBox(vec3 mouseWorldPos) {
        if (this.nodeVisibilityBox == null) return false;
        return this.mouseOverBox(mouseWorldPos, [this.nodeVisibilityBox, this.nodeVisibilityBox.contentBox]);
    }

    fun void hideIOBox() {

    }

    fun void showIOBox() {

    }

    fun void hideOptionsBox() {
        if (this.nodeOptionsBox == null) return;

        this.nodeOptionsBox --< this;
        0 => this.nodeOptionsBox.active;

        // // Order goes nodeNameBox --> jackModifierBox --> nodeContentBox --> nodeVisibilityBox
        // if (this.jackModifierBox != null && this.jackModifierBox.active) {
        //     this.nodeNameBox.posY() - (this.nodeNameBox.scaY() / 2.) - (this.jackModifierBox.contentBox.scaY() / 2.) => this.jackModifierBox.posY;
        //     this.jackModifierBox.posY() - (this.jackModifierBox.contentBox.scaY() / 2.) - (this.nodeContentBox.scaY() / 2.) => this.nodeContentBox.posY;
        //     this.nodeContentBox.posY() - (this.nodeContentBox.scaY() / 2.) - (this.nodeVisibilityBox.scaY() / 2.) => this.nodeVisibilityBox.posY;
        // // Order goes nodeNameBox --> nodeVisibilityBox
        // } else if (this.jackModifierBox == null || (this.jackModifierBox != null && !this.jackModifierBox.active)){
        //     this.nodeNameBox.posY() - (this.nodeNameBox.scaY() / 2.) - (this.nodeVisibilityBox.scaY() / 2.) => this.nodeVisibilityBox.posY;
        // }

    }

    fun void showOptionsBox() {
        if (this.nodeOptionsBox == null) return;

        this.nodeOptionsBox --> this;
        1 => this.nodeOptionsBox.active;

        // Order goes nodeNameBox --> nodeOptionsBox --> jackModifierBox --> nodeContentBox --> nodeVisibilityBox
    }

    fun void updatePos() {
        // If Node has all 5 boxes positions go in the following order:
        // nodeNameBox --> nodeOptionsBox --> nodeInputsModifierBox --> nodeInputsBox --> nodeOutputsModifierBox --> nodeOutputsBox --> nodeVisibilityBox
        // The only non-optional box is nodeNameBox

        [this.nodeNameBox] @=> ContentBox boxes[];

        if (this.nodeOptionsBox != null) {
            boxes << this.nodeOptionsBox;
        }

        if (this.nodeInputsModifierBox != null) {
            boxes << this.nodeInputsModifierBox;
        }

        if (this.nodeInputsBox != null) {
            boxes << this.nodeInputsBox;
        }

        if (this.nodeOutputsModifierBox != null) {
            boxes << this.nodeOutputsModifierBox;
        }

        if (this.nodeOutputsBox != null) {
            boxes << this.nodeOutputsBox;
        }

        if (this.nodeVisibilityBox != null) {
            boxes << this.nodeVisibilityBox;
        }

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

    fun void connect(UGen ugen, int inputJackIdx) {
        <<< "ERROR: Override the Connect function for Child Nodes." >>>;
    }

    fun void disconnect(UGen ugen, int inputJackIdx) {
        <<< "ERROR: Override the Disconnect function for Child Nodes." >>>;
    }

    fun void addJack() {
        <<< "ERROR: Override the addJack function for Child Nodes" >>>;
    }

    fun void removeJack() {
        <<< "ERROR: Override the removeJack function for Child Nodes" >>>;
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
}


public class Jack extends GGen {
    GTorus border;
    GCylinder jack;

    int ioType;
    int isConnected;
    UGen @ ugen;

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
        spork ~ this.setColor();
    }

    fun void setUgen(UGen ugen) {
        1 => this.isConnected;
        ugen @=> this.ugen;
    }

    fun void removeUgen() {
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

    // Data handling
    Step outs[0];

    // IO Type
    int ioType;

    // Jacks
    int numJacks;

    // Menus
    DropdownMenu @ openMenu;

    fun @construct(int numJacks, int ioType, string parentNodeID, float xScale) {
        // Create an IO box without menus
        IOBox(numJacks, null, ioType, parentNodeID, xScale);
    }


    fun @construct(int numStartJacks, Enum ioMenuEntries[], int ioType, string parentNodeID, float xScale) {
        // Member variables
        ioType => this.ioType;
        numStartJacks => this.numJacks;

        // Scale
        @(xScale, numStartJacks, 0.2) => this.contentBox.sca;

        // Color
        Color.GRAY => this.contentBox.color;

        // Position handling for Jacks Only vs. Jacks and Menus
        int xPosModifier;
        if (ioMenuEntries != null) {
            1 => xPosModifier;
            if (ioType == IOType.INPUT) {
                -1 => xPosModifier;
            }
        }

        // Jacks and Menus
        (this.contentBox.scaY() - 1) / 2. => float startPosY;
        for (int idx; idx < numStartJacks; idx++) {
            Jack jack(idx, ioType);
            Step out(0.);

            // Jack Position
            1.25 * xPosModifier => jack.posX;
            startPosY + (idx * -1) => jack.posY;

            // Add jack to list
            this.jacks << jack;
            this.outs << out;

            // Connect jack to IO box
            jack --> this;

            if (ioMenuEntries != null) {
                DropdownMenu menu(ioMenuEntries, parentNodeID, idx);

                // Menus position
                -0.75 * xPosModifier => menu.posX;
                startPosY + (idx * -1) => menu.posY;
                0.1 => menu.posZ;

                // Add menu to list
                this.menus << menu;

                // Connect menu to IO box
                menu --> this;
            }
        }

        // Names
        "IOBox " + this.ioType => this.name;
        "Content Box" => this.contentBox.name;

        // Connect boxes to IO box
        this.contentBox --> this;
    }

    fun void addJack(Enum menuSelections[]) {
        this.numJacks => int jackIdx;
        Jack jack(jackIdx, IOType.OUTPUT);
        DropdownMenu jackMenu(menuSelections, jackIdx);
        Step out(0.);

        // Update numJacks
        this.numJacks++;

        // Update contentBox scale
        this.numJacks => this.contentBox.scaY;
        (this.contentBox.scaY() - 1) / 2. => float startPosY;

        // Jack position
        1.25 => jack.posX;

        // Menu position
        -0.75 => jackMenu.posX;
        0.1 => jackMenu.posZ;

        // Add objects to lists
        this.jacks << jack;
        this.menus << jackMenu;
        this.outs << out;

        // Jack Connection
        jack --> this;
        jackMenu --> this;

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

        // Remove objects from lists
        this.jacks.popBack();
        this.menus.popBack();
        this.outs.popBack();

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
}


public class IOModifierBox extends ContentBox {
    BorderedBox @ addBox;
    BorderedBox @ removeBox;
    1 => int active;

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
    1 => int active;

    fun @construct(string optionNames[], float xScale) {
        optionNames.size() => this.numOptions;

        for (int idx; idx < optionNames.size(); idx++) {
            GText text;
            optionNames[idx] => text.text;
            @(3., 3., 3., 1.) => text.color;
            @(0., 0.5) => text.controlPoints;

            @(-1 * ((xScale - (xScale * 0.2)) / 2.), -1 * idx, 0.201) => text.pos;
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

    fun void updatePos() {
        for (int idx; idx < this.optionNames.size(); idx++) {
            Math.fabs(this.contentBox.posY()) - idx => this.optionNames[idx].posY;
        }
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
        1.2 => this.optionsBox.posX;
        0. => this.outputsBox.posX;
        -1.2 => this.inputsBox.posX;

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
