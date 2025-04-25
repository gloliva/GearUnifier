@import "../ui/menu.ck"


public class Node extends GGen {
    string nodeID;
    int numJacks;

    GText nodeName;
    GCube nodeNameBox;
    GCube nodeContentBox;
    JackModifierBox @ jackModifierBox;

    // Contents
    Jack jacks[0];
    DropdownMenu menus[0];

    fun @construct() {
        // Names
        "Node Name" => this.nodeName.name;
        "Node Name Box" => this.nodeNameBox.name;
        "Node Content Box" => this.nodeContentBox.name;
    }

    fun int mouseHoverNameBox(vec3 mouseWorldPos) {
        this.posX() + this.nodeNameBox.posX() * this.scaX() => float centerX;
        this.posY() + this.nodeNameBox.posY() * this.scaY() => float centerY;
        (this.nodeNameBox.scaX() * this.scaX()) / 2.0 => float halfW;
        (this.nodeNameBox.scaY() * this.scaY()) / 2.0 => float halfH;

        if (
            mouseWorldPos.x >= centerX - halfW && mouseWorldPos.x <= centerX + halfW
            && mouseWorldPos.y >= centerY - halfH && mouseWorldPos.y <= centerY + halfH
        ) {
            return true;
        }

        return false;
    }

    fun int mouseHoverContentBox(vec3 mouseWorldPos) {
        this.posX() + this.nodeContentBox.posX() * this.scaX() => float centerX;
        this.posY() + this.nodeContentBox.posY() * this.scaY() => float centerY;
        (this.nodeContentBox.scaX() * this.scaX()) / 2.0 => float halfW;
        (this.nodeContentBox.scaY() * this.scaY()) / 2.0 => float halfH;

        if (
            mouseWorldPos.x >= centerX - halfW && mouseWorldPos.x <= centerX + halfW
            && mouseWorldPos.y >= centerY - halfH && mouseWorldPos.y <= centerY + halfH
        ) {
            return true;
        }

        return false;
    }

    fun int mouseHoverOverJack(vec3 mouseWorldPos) {
        -1 => int jackIdx;

        for (int idx; idx < this.jacks.size(); idx++) {
            this.jacks[idx] @=> Jack jack;

            this.posX() + jack.posX() * this.scaX() => float centerX;
            this.posY() + jack.posY() * this.scaY() => float centerY;
            (jack.scaX() * this.scaX()) / 2.0 => float halfW;
            (jack.scaY() * this.scaY()) / 2.0 => float halfH;

            if (
                mouseWorldPos.x >= centerX - halfW && mouseWorldPos.x <= centerX + halfW
                && mouseWorldPos.y >= centerY - halfH && mouseWorldPos.y <= centerY + halfH
            ) {
                idx => jackIdx;
                break;
            }
        }

        return jackIdx;
    }

    fun int mouseHoverOverDropdownMenu(vec3 mouseWorldPos) {
        -1 => int dropdownMenuIdx;

        for (int idx; idx < this.menus.size(); idx++) {
            this.menus[idx] @=> DropdownMenu menu;

            this.posX() + (menu.posX() * this.scaX()) + (menu.selectedBox.box.posX() * this.scaX()) => float centerX;
            this.posY() + (menu.posY() * this.scaY()) + (menu.selectedBox.box.posY() * this.scaY()) => float centerY;
            (menu.selectedBox.box.scaX() * menu.scaX() * this.scaX()) / 2.0 => float halfW;
            (menu.selectedBox.box.scaY() * menu.scaY() * this.scaY()) / 2.0 => float halfH;

            if (
                mouseWorldPos.x >= centerX - halfW && mouseWorldPos.x <= centerX + halfW
                && mouseWorldPos.y >= centerY - halfH && mouseWorldPos.y <= centerY + halfH
            ) {
                idx => dropdownMenuIdx;
                break;
            }
        }

        return dropdownMenuIdx;
    }

    fun void connect(UGen ugen, int inputJackIdx) {
        <<< "ERROR: Override the Connect function for Child Nodes." >>>;
    }

    fun void disconnect(UGen ugen, int inputJackIdx) {
        <<< "ERROR: Override the Disconnect function for Child Nodes." >>>;
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
    int outputNodeIdx;
    int outputNodeJackIdx;
    vec2 outputJackPos;

    int inputNodeIdx;
    int inputNodeJackIdx;
    vec2 inputJackPos;

    GLines wire;

    fun @construct(int outputNodeIdx, int outputNodeJackIdx, vec2 outputJackPos, vec3 mouseWorldPos) {
        outputNodeIdx => this.outputNodeIdx;
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
        "Open Connection: Node" + this.outputNodeIdx + " Jack" + this.outputNodeJackIdx => this.name;
        "Wire" => this.wire.name;

        // Connections
        this.wire --> this --> GG.scene();
    }

    fun void completeWire(int inputNodeIdx, int inputNodeJackIdx, vec2 inputJackPos) {
        inputNodeIdx => this.inputNodeIdx;
        inputNodeJackIdx => this.inputNodeJackIdx;
        inputJackPos => this.inputJackPos;
        "Completed Connection: Node" + this.outputNodeIdx + " Jack" + this.outputNodeJackIdx + " -> Node" + this.inputNodeIdx + " Jack" + this.inputNodeJackIdx => this.name;

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

    fun int mouseHoverOverWire(vec3 mouseWorldPos) {
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
            if (!this.isConnected) {
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


public class JackModifierBox extends GGen {
    GCube contentBox;
    BorderedBox @ addBox;
    BorderedBox @ removeBox;

    fun @construct(float xScale) {
        new BorderedBox("+", 0.5, 0.5) @=> this.addBox;
        new BorderedBox("-", 0.5, 0.5) @=> this.removeBox;

        // Position
        0.5 => this.addBox.posX;
        -0.5 => this.removeBox.posX;

        // Scale
        @(xScale, 1., 0.2) => this.contentBox.sca;

        // Color
        Color.BLACK => this.contentBox.color;

        // Names
        "Jack Modifier Box" => this.name;
        "Add Bordered Box" => this.addBox.name;
        "Remove Bordered Box" => this.removeBox.name;

        // Connections
        this.contentBox --> this;
        this.addBox --> this;
        this.removeBox --> this;
    }
}
