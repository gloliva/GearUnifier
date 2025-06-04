// Imports
@import "../../utils.ck"
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


public class Distortion extends Chugen {
    2 => int type;
    2. => float scale;
    2. => float factor;
    0.5 => float mix;

    fun void setType(int type) {
        type => this.type;
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
        in => float distortedValue;

        if (this.type == 0) {
            this.halfRect(in) => distortedValue;
        } else if (this.type == 1) {
            this.fullRect(in) => distortedValue;
        } else if (this.type == 2) {
            this.sintan(in) => distortedValue;
        } else if (this.type == 3) {
            this.modDistort(in) => distortedValue;
        }

        return distortedValue;

        // return (in * this.mix) + (distortedValue * (1 - this.mix));
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

    fun float halfRect(float x) {
        x * this.scale => x;

        if (x > 0) return x;

        return 0.;
    }

    fun float cube(float x) {
        return Math.pow(x * this.scale, 3);
    }

    fun float fullRect(float x) {
        x * this.scale => x;
        return Math.fabs(x);
    }

    fun float exponential(float x, float factor) {
        x * this.scale => x;
        return Math.sgn(x) * (1.0 - Math.exp(-1 * factor * Math.fabs(x)));
    }

    fun float otherExp(float x) {
        x * this.scale => x;
        return Math.sgn(x) * (1.0 - Math.exp(-1 * Math.pow(x, 2) / Math.fabs(x)));
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
        this.nodeInputsModifierBox --> this;
        this.nodeInputsBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();
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

        // Node data
        data.set("nodeClass", Type.of(this).name());
        data.set("nodeID", this.nodeID);
        data.set("posX", this.posX());
        data.set("posY", this.posY());
        data.set("posZ", this.posZ());
        data.set("numInputs", this.nodeInputsBox.numJacks);

        // Input menu data
        HashMap inputMenuData;
        for (int idx; idx < this.nodeInputsBox.menus.size(); idx++) {
            this.nodeInputsBox.menus[idx] @=> DropdownMenu menu;
            inputMenuData.set(idx, menu.getSelectedEntry().id);
        }
        data.set("inputMenuData", inputMenuData);

        // Wavefolder parameters
        data.set("type", this.distortion.type);
        data.set("factor", this.distortion.factor);
        data.set("mix", this.distortion.mix);

        return data;
    }
}
