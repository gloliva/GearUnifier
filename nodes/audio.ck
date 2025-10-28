// Imports
@import "base.ck"


public class AudioNode extends Node {
    // Audio Nodes do their own content box and Jacks handling
    string ioType;

    fun @construct(int type) {
        // Member variables
        IOType.toString(type) => this.ioType;

        // Set Node ID
        "Audio " + this.ioType + " Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Audio " + this.ioType, 2.) @=> this.nodeNameBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);
        data.set("ioType", this.ioType);

        if (this.nodeInputsBox != null) {
            data.set("numJacks", this.nodeInputsBox.numJacks);
        }

        if (this.nodeOutputsBox != null) {
            data.set("numJacks", this.nodeOutputsBox.numJacks);
        }

        return data;
    }
}


public class AudioOutNode extends AudioNode {
    fun @construct(int numOuts) {
        AudioNode(IOType.OUTPUT);

        // Audio Out sends signals to the DAC
        // Therefore, all jacks are Inputs
        new IOBox(numOuts, IOType.INPUT, this.nodeID, 2.) @=> this.nodeInputsBox;
        this.nodeInputsBox --> this;

        // Update box positions
        this.updatePos();
    }

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        if (inputJackIdx >= this.nodeInputsBox.numJacks) {
            return;
        }

        ugen => dac.chan(inputJackIdx);
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {
        if (inputJackIdx >= this.nodeInputsBox.numJacks) {
            return;
        }

        ugen =< dac.chan(inputJackIdx);
    }
}


public class AudioInNode extends AudioNode {

    fun @construct(int numIns) {
        AudioNode(IOType.INPUT);

        // Audio In sends receives signals and sends them from ADC
        // Therefore, all jacks are Outputs
        new IOBox(numIns, IOType.OUTPUT, this.nodeID, 2.) @=> this.nodeOutputsBox;
        this.nodeOutputsBox --> this;

        for (int i; i < numIns; i++) {
            // Set the gain as the UGen for the jack
            this.nodeOutputsBox.jacks[i].setUgen(adc.chan(i));
        }

        // Update box positions
        this.updatePos();

    }
}
