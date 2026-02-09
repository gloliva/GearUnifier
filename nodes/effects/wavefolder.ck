// Imports
@import "../../utils.ck"
@import "../base.ck"
@import "HashMap"

public class WavefolderInputType {
    new Enum(0, "Wave In") @=> static Enum WAVE_IN;
    new Enum(1, "Threshold") @=> static Enum THRESHOLD;
    new Enum(2, "Gain") @=> static Enum GAIN;
    new Enum(3, "Mix") @=> static Enum MIX;

    [
        WavefolderInputType.WAVE_IN,
        WavefolderInputType.THRESHOLD,
        WavefolderInputType.GAIN,
        WavefolderInputType.MIX,
    ] @=> static Enum allTypes[];
}


public class Wavefolder extends Chugen {
    0.6 => float threshold;
    20.0 => float scale;
    0.5 => float mix;

    fun void setThreshold(float threshold) {
        threshold => this.threshold;
    }

    fun void setScale(float scale) {
        scale => this.scale;
    }

    fun void setMix(float mix) {
        mix => this.mix;
    }

    fun float tick(float in) {
        return this.shapeOne(in) * this.mix + this.shapeThree(in) * (1 - this.mix);
    }

    fun float shapeOne(float in) {
        in * scale => float x;

        4 * threshold => float period;
        (x + threshold) % period => x;
        if (x < 2 * threshold) {
            return x - threshold;
        } else {
            return 3 * threshold - x;
        }
    }

    fun float shapeTwo(float in) {
        in * scale => float x;
        return Math.tanh(x);
    }

    fun float shapeThree(float in) {
        in * scale => float x;

        this.threshold => float currThreshold;

        repeat(5) {
            if (x > currThreshold) {
                2 * currThreshold - x => x;
            } else if (x < -currThreshold) {
                -2 * currThreshold - x => x;
            }

            currThreshold / 2 => currThreshold;
        }

        return x;
    }

    fun float shapeFour(float in) {
        // Scale the input (boost to exceed threshold)
        in * scale => float x;

        4.0 * threshold => float period;

        // Triangle folding: symmetric around ±threshold
        // Step 1: Shift, mod, center
        (((x + threshold) % period + period) % period - 2.0 * threshold) => x;

        // Step 2: Reflect to triangle shape
        return threshold - Math.fabs(x);
    }
}


public class WavefolderNode extends Node {
    Wavefolder wavefolder;

    // Data handling
    int inputDataMap[0];

    fun @construct() {
        WavefolderNode(1, 4.);
    }

    fun @construct(int numInputs, float xScale) {
        // Set node ID and name
        "Wavefolder Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Wavefolder", xScale) @=> this.nodeNameBox;

        // Create options box

        // Create inputs box
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(numInputs, WavefolderInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        for (0 => int i; i < WavefolderInputType.allTypes.size(); i++) {
            this.inputDataMap << -1;
        }

        // Create outputs box
        new IOBox(1, [new Enum(0, "Wave Out")], IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(0);
        this.nodeOutputsBox.jacks[0].setUgen(this.wavefolder);

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

        // Shreds
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        this.addShreds([processInputsShred]);
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == WavefolderInputType.WAVE_IN.id) {
            ugen => this.wavefolder;
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
        if (dataType == WavefolderInputType.WAVE_IN.id) {
            ugen =< this.wavefolder;
        }
    }

    fun void addJack(int ioType) {
         if (ioType == IOType.INPUT) {
            this.nodeInputsBox.addJack(WavefolderInputType.allTypes);
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

                if (dataType == WavefolderInputType.THRESHOLD.id) {
                    Std.scalef(value, -0.5, 0.5, 0.05, 0.9) => this.wavefolder.setThreshold;
                } else if (dataType == WavefolderInputType.GAIN.id) {
                    Std.scalef(value, -0.5, 0.5, 5., 40.) => this.wavefolder.setScale;
                } else if (dataType == WavefolderInputType.MIX.id) {
                    Std.scalef(value, -0.5, 0.5, 0., 1.) => this.wavefolder.setMix;
                }
            }
            10::ms => now;
        }
    }

    fun HashMap serialize() {
        super.serialize() @=> HashMap data;

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
        data.set("threshold", this.wavefolder.threshold);
        data.set("scale", this.wavefolder.scale);
        data.set("mix", this.wavefolder.mix);

        return data;
    }
}
