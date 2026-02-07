@import {"../events.ck", "../utils.ck"}
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


public class AmbPannerNode extends Node {
    int order;

    // Ambisonics objects
    AmbPanACN @ amb;
    Patch @ aziPatch;
    Patch @ elePatch;

    fun @construct() {
        AmbPannerNode(3, 4.);
    }

    fun @construct(int order, float xScale) {
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

        // Create inputs box
        AmbPannerInputType.allTypes @=> this.inputTypes;
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(1, this.inputTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
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
        if (this.amb.outChannels > prevOutChannels) {
            // TODO: Add jacks
        } else {
            // Remove jacks
            repeat(prevOutChannels - this.amb.outChannels) {
                this.removeJack(IOType.OUTPUT);
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
