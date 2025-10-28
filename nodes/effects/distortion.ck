// Imports
@import "../../utils.ck"
@import "../../ui/menu.ck"
@import "../base.ck"
@import "HashMap"


public class DistortionInputType {
    new Enum(0, "Wave In") @=> static Enum WAVE_IN;
    new Enum(1, "Factor") @=> static Enum FACTOR;
    new Enum(2, "Gain") @=> static Enum GAIN;
    new Enum(3, "Mix") @=> static Enum MIX;

    [
        DistortionInputType.WAVE_IN,
        DistortionInputType.FACTOR,
        DistortionInputType.GAIN,
        DistortionInputType.MIX,
    ] @=> static Enum allTypes[];
}


public class DistortionTypes {
    new Enum(0, "Type 1") @=> static Enum TYPE_1;
    new Enum(1, "Type 2") @=> static Enum TYPE_2;
    new Enum(2, "Type 3") @=> static Enum TYPE_3;
    new Enum(3, "Type 4") @=> static Enum TYPE_4;

    [
        DistortionTypes.TYPE_1,
        DistortionTypes.TYPE_2,
        DistortionTypes.TYPE_3,
        DistortionTypes.TYPE_4,
    ] @=> static Enum allTypes[];
}


public class DistortionOptionsBox extends OptionsBox {
    DropdownMenu @ mixMenu;
    DropdownMenu @ dist1Menu;
    DropdownMenu @ dist2Menu;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Midi Channel Select Menu
        new DropdownMenu([new Enum(0, "Solo"), new Enum(1, "Mix")]) @=> this.mixMenu;
        this.mixMenu.updateSelectedEntry(0);

        // Synth Mode Select Menu
        new DropdownMenu(DistortionTypes.allTypes) @=> this.dist1Menu;
        this.dist1Menu.updateSelectedEntry(0);

        // Latch Select Menu
        new DropdownMenu(DistortionTypes.allTypes) @=> this.dist2Menu;
        this.dist2Menu.updateSelectedEntry(0);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.mixMenu.pos;
        @(0.75, this.optionNames[1].posY(), 0.201) => this.dist1Menu.pos;
        @(0.75, this.optionNames[2].posY(), 0.201) => this.dist2Menu.pos;

        // Name
        "Mix Dropdown Menu" => this.mixMenu.name;
        "Dist1 Dropdown Menu" => this.dist1Menu.name;
        "Dist2 Dropdown Menu" => this.dist2Menu.name;
        "Distortion Options Box" => this.name;

        // Connections
        this.mixMenu --> this;
        this.dist1Menu --> this;
        this.dist2Menu --> this;
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
        if (this.mixMenu.expanded) {
            this.parent()$Node @=> Node parentNode;
            this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.mixMenu) => int hoveredMenuEntryIdx;
            this.mixMenu.highlightHoveredEntry(hoveredMenuEntryIdx);
        }

        if (this.dist1Menu.expanded) {
            this.parent()$Node @=> Node parentNode;
            this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.dist1Menu) => int hoveredMenuEntryIdx;
            this.dist1Menu.highlightHoveredEntry(hoveredMenuEntryIdx);
        }

        if (this.dist2Menu.expanded) {
            this.parent()$Node @=> Node parentNode;
            this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.dist2Menu) => int hoveredMenuEntryIdx;
            this.dist2Menu.highlightHoveredEntry(hoveredMenuEntryIdx);
        }
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        Type.of(this.parent()).name() => string parentName;

        // MidiIn Nodes
        if (parentName == DistortionNode.typeOf().name()) {
            this.parent()$DistortionNode @=> DistortionNode parentNode;

            // Check if channel menu is open and clicking on an option
            -1 => int mixMenuEntryIdx;
            if (this.mixMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.mixMenu) => mixMenuEntryIdx;

                if (mixMenuEntryIdx != -1) {
                    this.mixMenu.updateSelectedEntry(mixMenuEntryIdx);
                    this.mixMenu.getSelectedEntry() @=> Enum selectedMix;
                    selectedMix.id => parentNode.setMode;
                    this.mixMenu.collapse();
                    0 => this.menuOpen;
                    return true;
                }
            }

            // Check if clicking on channel menu && other menus are closed
            if (!this.dist1Menu.expanded && !this.dist2Menu.expanded && parentNode.mouseOverBox(mouseWorldPos, [this, this.mixMenu, this.mixMenu.selectedBox.box])) {
                if (!this.mixMenu.expanded) {
                    this.mixMenu.expand();
                    1 => this.menuOpen;
                    return true;
                }
            } else {
                this.mixMenu.collapse();
            }

            // Check if mode menu is open and clicking on an option
            -1 => int dist1MenuEntryIdx;
            if (this.dist1Menu.expanded && mixMenuEntryIdx == -1) {
                this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.dist1Menu) => dist1MenuEntryIdx;

                if (dist1MenuEntryIdx != -1) {
                    this.dist1Menu.updateSelectedEntry(dist1MenuEntryIdx);
                    this.dist1Menu.getSelectedEntry() @=> Enum selectedMode;
                    selectedMode.id => parentNode.setDist1Type;
                    this.dist1Menu.collapse();
                    0 => this.menuOpen;
                    return true;
                }
            }

            // Check if clicking on mode menu && other menus are closed
            if (mixMenuEntryIdx == -1 && !this.mixMenu.expanded && !this.dist2Menu.expanded && parentNode.mouseOverBox(mouseWorldPos, [this, this.dist1Menu, this.dist1Menu.selectedBox.box])) {
                if (!this.dist1Menu.expanded) {
                    this.dist1Menu.expand();
                    1 => this.menuOpen;
                    return true;
                }
            } else {
                this.dist1Menu.collapse();
            }

            -1 => int dist2MenuEntryIdx;
            if (this.dist2Menu.expanded && mixMenuEntryIdx == -1 && dist1MenuEntryIdx == -1) {
                this.mouseOverMenuEntry(mouseWorldPos, parentNode, this.dist2Menu) => dist2MenuEntryIdx;

                if (dist2MenuEntryIdx != -1) {
                    this.dist2Menu.updateSelectedEntry(dist2MenuEntryIdx);
                    this.dist2Menu.getSelectedEntry() @=> Enum selectedLatch;
                    selectedLatch.id => parentNode.setDist2Type;
                    this.dist2Menu.collapse();
                    0 => this.menuOpen;
                    return true;
                }
            }

            // Check if clicking on latch menu && other menus are closed
            if (dist2MenuEntryIdx == -1 && !this.mixMenu.expanded && !this.dist1Menu.expanded && parentNode.mouseOverBox(mouseWorldPos, [this, this.dist2Menu, this.dist2Menu.selectedBox.box])) {
                if (!this.dist2Menu.expanded) {
                    this.dist2Menu.expand();
                    1 => this.menuOpen;
                    return true;
                }
            } else {
                this.dist1Menu.collapse();
            }


            // Check if no menus are open
            if (!this.mixMenu.expanded
                && !this.dist1Menu.expanded
                && !this.dist2Menu.expanded)
            {
                0 => this.menuOpen;
            }
        }

        return false;
    }
}


public class Distortion extends Chugen {
    0 => int mode;
    0 => int dist1Type;
    0 => int dist2Type;

    2. => float scale;
    2. => float factor;
    0.5 => float mix;

    fun void setMode(int mode) {
        mode => this.mode;
    }

    fun void setDist1Type(int type) {
        type => this.dist1Type;
    }

    fun void setDist2Type(int type) {
        type => this.dist2Type;
    }

    fun void setFactor(float factor) {
        factor => this.factor;
    }

    fun void setScale(float scale) {
        scale => this.scale;
    }

    fun void setMix(float mix) {
        mix => this.mix;
    }

    fun float tick(float in) {
        in => float dist1Value;
        in => float dist2Value;

        // Distortion 1
        if (this.dist1Type == 0) {
            this.modDistort(in) => dist1Value;
        } else if (this.dist1Type == 1) {
            this.modDistort2(in) => dist1Value;
        } else if (this.dist1Type == 2) {
            this.sintan(in) => dist1Value;
        } else if (this.dist1Type == 3) {
            this.cube(in) => dist1Value;
        }

        // Distortion 2
        if (this.dist2Type == 0) {
            this.modDistort(in) => dist2Value;
        } else if (this.dist2Type == 1) {
            this.modDistort2(in) => dist2Value;
        } else if (this.dist2Type == 2) {
            this.sintan(in) => dist2Value;
        } else if (this.dist2Type == 3) {
            this.cube(in) => dist2Value;
        }

        if (this.mode == 0) return dist1Value;

        return (dist1Value * this.mix) + (dist2Value * (1 - this.mix));
    }

    fun float mod(float n, float d) {
        Math.fmod(n, d) => n;
        if (n < 0.) n + d => n;
        return n;
    }

    fun float modDistort(float x) {
        return Math.fabs(this.mod(2 * this.scale * x + 2, this.factor) - 2) - 1;
    }

    fun float modDistort2(float x) {
        return this.mod(this.scale * x + 1, 2) - 1;
    }

    fun float sintan(float x) {
        return Math.sin(x * this.scale) * Math.tanh(x * this.scale);
    }

    fun float cube(float x) {
        return Math.pow(x * this.scale, 3);
    }

    fun float fullRect(float x) {
        x * this.scale => x;
        return Math.fabs(x);
    }
}


public class DistortionNode extends Node {
    Distortion distortion;

    fun @construct() {
        DistortionNode(1, 4.);
    }

    fun @construct(int numInputs, float xScale) {
        // Set node ID and name
        "Distortion Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Distortion", xScale) @=> this.nodeNameBox;

        // Create options box
        new DistortionOptionsBox(["Mix", "Dist1", "Dist2"], xScale) @=> this.nodeOptionsBox;

        // Create inputs box
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(numInputs, DistortionInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;

        // Create outputs box
        new IOBox(1, [new Enum(0, "Wave Out")], IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(0);
        this.nodeOutputsBox.jacks[0].setUgen(this.distortion);

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

    fun void setMode(int mode) {
        mode => this.distortion.setMode;
    }

    fun void setDist1Type(int type) {
        type => this.distortion.setDist1Type;
    }

    fun void setDist2Type(int type) {
        type => this.distortion.setDist2Type;
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == DistortionInputType.WAVE_IN.id) {
            ugen => this.distortion;
        }

    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        // Remove dataType mapping
        this.nodeInputsBox.removeDataTypeMapping(inputJackIdx);

        // Remove any additional mappings
        if (dataType == DistortionInputType.WAVE_IN.id) {
            ugen =< this.distortion;
        }
    }

    fun void addJack(int ioType) {
         if (ioType == IOType.INPUT) {
            this.nodeInputsBox.addJack(DistortionInputType.allTypes);
        }
        this.updatePos();
    }

    fun void removeJack(int ioType) {
        if (ioType == IOType.INPUT) {
            this.nodeInputsBox.removeJack() @=> Enum removedMenuSelection;
        }
        this.updatePos();
    }

    fun void processInputs() {
        while (this.nodeActive) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                this.nodeInputsBox.getDataTypeMapping(idx) => int dataType;
                if (dataType == -1) continue;

                // Value can be from a audio rate UGen (which uses last()) or a control rate UGen (which uses next())
                this.nodeInputsBox.jacks[idx].ugen @=> UGen ugen;
                if (ugen == null) {
                    continue;
                }

                float value;
                if (Type.of(ugen).name() == Step.typeOf().name()) {
                    (ugen$Step).next() => value;
                } else {
                    ugen.last() => value;
                }

                if (dataType == DistortionInputType.FACTOR.id) {
                    Std.scalef(value, -0.5, 0.5, 1., 6.) => this.distortion.setFactor;
                } else if (dataType == DistortionInputType.GAIN.id) {
                    Std.scalef(value, -0.5, 0.5, 3., 50.) => this.distortion.setScale;
                } else if (dataType == DistortionInputType.MIX.id) {
                    Std.scalef(value, -0.5, 0.5, 0., 1.) => this.distortion.setMix;
                }
            }
            10::ms => now;
        }
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        // Node data
        data.set("numInputs", this.nodeInputsBox.numJacks);

        // Input menu data
        HashMap inputMenuData;
        for (int idx; idx < this.nodeInputsBox.menus.size(); idx++) {
            this.nodeInputsBox.menus[idx] @=> DropdownMenu menu;
            inputMenuData.set(idx, menu.getSelectedEntry().id);
        }
        data.set("inputMenuData", inputMenuData);

        // Wavefolder parameters
        data.set("mode", this.distortion.mode);
        data.set("dist1Type", this.distortion.dist1Type);
        data.set("dist2Type", this.distortion.dist2Type);
        data.set("scale", this.distortion.scale);
        data.set("factor", this.distortion.factor);
        data.set("mix", this.distortion.mix);

        return data;
    }
}
