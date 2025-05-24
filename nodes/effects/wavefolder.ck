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
    0.7 => float threshold;
    10.0 => float scale;
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
        return this.shapeOne(in) * this.mix + this.shapeTwo(in) * (1 - this.mix);
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
    }

    fun void setInputDataTypeMapping(Enum wavefolderInputType, int jackIdx) {
        wavefolderInputType.id => this.inputDataMap[jackIdx];
    }

    fun int getInputDataTypeMapping(int jackIdx) {
        return this.inputDataMap[jackIdx];
    }

    fun void removeInputDataTypeMapping(int jackIdx) {
        -1 => this.inputDataMap[jackIdx];
    }

    fun void connect(UGen ugen, int inputJackIdx) {
        this.inputDataMap[inputJackIdx] => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        if (dataType == WavefolderInputType.WAVE_IN.id) {
            ugen => this.wavefolder;
        }

    }

    fun void disconnect(UGen ugen, int inputJackIdx) {
        this.inputDataMap[inputJackIdx] => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

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
        while (true) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                if (this.inputDataMap[idx] == -1) {
                    continue;
                }

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

                if (this.inputDataMap[idx] == WavefolderInputType.THRESHOLD.id) {
                    Std.scalef(value, -0.5, 0.5, 0.1, 0.9) => this.wavefolder.setThreshold;
                } else if (this.inputDataMap[idx] == WavefolderInputType.GAIN.id) {
                    Std.scalef(value, -0.5, 0.5, 1., 20.) => this.wavefolder.setScale;
                } else if (this.inputDataMap[idx] == WavefolderInputType.MIX.id) {
                    Std.scalef(value, -0.5, 0.5, 0., 1.) => this.wavefolder.setMix;
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
        data.set("threshold", this.wavefolder.threshold);
        data.set("scale", this.wavefolder.scale);
        data.set("mix", this.wavefolder.mix);

        return data;
    }
}
