@import {"../events.ck", "../utils.ck"}
@import "../ui/menu.ck"
@import "base.ck"
@import "Patch"
@import "HashMap"
//@import "AmbPanACN"  // Add this import when AmbPan is chumpified


public class AmbPannerInputType {
    new Enum(0, "Wave In") @=> static Enum WAVE_IN;
    new Enum(1, "Azimuth") @=> static Enum AZIMUTH;
    new Enum(2, "Elevation") @=> static Enum ELEVATION;
    [
        AmbPannerInputType.WAVE_IN,
        AmbPannerInputType.AZIMUTH,
        AmbPannerInputType.ELEVATION,
    ] @=> static Enum allTypes[];
}


public class AmbPannerOptionsBox extends OptionsBox {
    DropdownMenu @ orderMenu;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Order Select Menu
        Enum orderOptions[0];
        for (1 => int orderNum; orderNum < AmbPannerNode.MAX_ORDER + 1; orderNum++) {
            orderOptions << new Enum(orderNum, "" + orderNum);
        }
        new DropdownMenu(orderOptions) @=> this.orderMenu;
        this.orderMenu.updateSelectedEntry(2);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.orderMenu.pos;

        // Name
        "Order Dropdown Menu" => this.orderMenu.name;
        "AmbPanner Options Box" => this.name;

        // Connections
        this.orderMenu --> this;
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
        if (this.orderMenu.expanded) {
            this.parent()$Node @=> Node parentNode;
            this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.orderMenu) => int hoveredMenuEntryIdx;
            this.orderMenu.highlightHoveredEntry(hoveredMenuEntryIdx);
        }
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        Type.of(this.parent()).name() => string parentName;

        // AmbPanner Node
        if (parentName == AmbPannerNode.typeOf().name()) {
            this.parent()$AmbPannerNode @=> AmbPannerNode parentNode;

            // Check if order menu is open and clicking on an option
            -1 => int mixMenuEntryIdx;
            if (this.orderMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.orderMenu) => mixMenuEntryIdx;

                if (mixMenuEntryIdx != -1) {
                    this.orderMenu.updateSelectedEntry(mixMenuEntryIdx);
                    this.orderMenu.getSelectedEntry() @=> Enum selectedOrder;
                    selectedOrder.id => parentNode.setOrder;
                    this.orderMenu.collapse();
                    0 => this.menuOpen;
                    return true;
                }
            }

            // Check if clicking on channel menu && other menus are closed
            if (parentNode.mouseOverBox(mouseWorldPos, [this, this.orderMenu, this.orderMenu.selectedBox.box])) {
                if (!this.orderMenu.expanded) {
                    this.orderMenu.expand();
                    1 => this.menuOpen;
                    return true;
                }
            } else {
                this.orderMenu.collapse();
            }
        }

        return false;
    }
}


public class AmbPannerNode extends Node {
    7 => static int MAX_ORDER;
    int order;

    // Ambisonics variables
    AmbPanACN @ amb;
    Patch @ aziPatch;
    Patch @ elePatch;

    fun @construct() {
        AmbPannerNode(3, 1, 4.);
    }

    fun @construct(int order, int numInputs, float xScale) {
        order => this.order;

        // Instantiate panner
        new AmbPanACN(order) @=> this.amb;

        // Set up azimuth and elevation changes through Patch
        new Patch(this.amb, "azimuth") @=> this.aziPatch;
        new Patch(this.amb, "elevation") @=> this.elePatch;

        this.aziPatch => blackhole;
        this.elePatch => blackhole;

        // Set node ID and name
        "AmbPanner Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("AmbPanner", xScale) @=> this.nodeNameBox;

        // Create options box
        new AmbPannerOptionsBox(["Order"], xScale) @=> this.nodeOptionsBox;

        // Create inputs box
        AmbPannerInputType.allTypes @=> this.inputTypes;
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(numInputs, this.inputTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        this.nodeInputsBox.setInput(AmbPannerInputType.WAVE_IN, 0);

        // Create outputs box
        Enum outputTypes[0];
        for (int out; out < amb.outChannels(); out++) {
            outputTypes << new Enum(out, "Chan " + (out + 1));
        }
        outputTypes @=> this.outputTypes;
        new IOBox(this.outputTypes.size(), this.outputTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;

        // Map ambisonics outputs channels to node outputs
        for (int out; out < this.amb.outChannels(); out++) {
            this.nodeOutputsBox.setOutput(outputTypes[out], out, this.amb.chan(out));
        }

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeOptionsBox --> this;
        this.nodeInputsModifierBox --> this;
        this.nodeInputsBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();
    }

    fun void setOrder(int order) {
        this.amb.outChannels() => int prevOutChannels;
        order => this.order;

        // Update the order in the panner
        this.order => this.amb.order;

        // Update number of jacks
        if (this.amb.outChannels() > prevOutChannels) {
            // Add jacks
            for (prevOutChannels => int out; out < this.amb.outChannels(); out++) {
                this.outputTypes << new Enum(out, "Chan " + (out + 1));
            }

            for (prevOutChannels => int out; out < this.amb.outChannels(); out++) {
                this.addJack(IOType.OUTPUT);
                this.nodeOutputsBox.setOutput(this.outputTypes[out], out, this.amb.chan(out));
            }
        } else {
            // Remove jacks
            repeat(prevOutChannels - this.amb.outChannels()) {
                this.removeJack(IOType.OUTPUT);
                this.outputTypes.popBack();
            }
        }
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "AmbPanner Connect: No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        // Connect input Wave to the ambisonics panner
        if (dataType == AmbPannerInputType.WAVE_IN.id) {
            ugen => this.amb;
            <<< "Connecting to WAVE IN" >>>;
        // Connect input signal to the azimuth patch
        } else if (dataType == AmbPannerInputType.AZIMUTH.id) {
            ugen => this.aziPatch;
            <<< "Connecting to AZIMUTH" >>>;
        // Connect input signal to the elevation patch
        } else if (dataType == AmbPannerInputType.ELEVATION.id) {
            ugen => this.elePatch;
            <<< "Connecting to ELEVATION" >>>;
        }
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "AmbPanner Connect: No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        // Disconnect input Wave from the ambisonics panner
        if (dataType == AmbPannerInputType.WAVE_IN.id) {
            ugen =< this.amb;
            <<< "Disconnecting from WAVE IN" >>>;
        // Connect input signal to the azimuth patch
        } else if (dataType == AmbPannerInputType.AZIMUTH.id) {
            ugen =< this.aziPatch;
            <<< "Disconnecting from AZIMUTH" >>>;
        // Connect input signal to the elevation patch
        } else if (dataType == AmbPannerInputType.ELEVATION.id) {
            ugen =< this.elePatch;
            <<< "Disconnecting from ELEVATION" >>>;
        }
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        // Panner data
        data.set("order", this.order);

        return data;
    }
}
