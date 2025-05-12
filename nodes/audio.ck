// Imports
@import "base.ck"


public class AudioNode extends Node {
    // Audio Nodes do their own content box and Jacks handling
    string ioType;

    fun @construct(int type) {
        // Member variables
        IOType.toString(type) => this.ioType;

        // Node name box
        new NameBox("Audio " + this.ioType, 2., 1.) @=> this.nodeNameBox;

        // // Position
        // 0.5 - (this.numJacks / 2.) => this.contentBox.posY;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;
        // @(2., this.numJacks, 0.2) => this.contentBox.sca;

        // // Color
        // Color.GRAY => this.contentBox.color;

        // // Handle Jacks
        // IOType.INPUT => int jackType;
        // if (type == IOType.INPUT) {
        //     IOType.OUTPUT => jackType;
        // }

        // for (int idx; idx < numJacks; idx++) {
        //     Jack jack(idx, jackType);

        //     // Jack Position
        //     idx * -1. => jack.posY;

        //     // Jack Connection
        //     jack --> this;
        //     this.jacks << jack;
        // }

        // Names
        "Audio " + this.ioType + " Node" => this.name;

        // Set ID
        Std.itoa(Math.random()) => string randomID;
        this.name() + " ID " + randomID => this.nodeID;

        // Connections
        this.nodeNameBox --> this;
    }
}


public class AudioOutNode extends AudioNode {
    fun @construct(int numOuts) {
        AudioNode(IOType.OUTPUT);

        // Audio Out sends signals to the DAC
        // Therefore, all jacks are Inputs
        Enum test(0, "Test");
        <<< "Here?" >>>;
        new IOBox(numOuts, IOType.INPUT, 2.) @=> this.nodeInputsBox;
        <<< "Here again?" >>>;
        this.nodeInputsBox --> this;
    }

    fun void connect(UGen ugen, int inputJackIdx) {
        if (inputJackIdx >= this.numJacks) {
            return;
        }

        ugen => dac.chan(inputJackIdx);
    }

    fun void disconnect(UGen ugen, int inputJackIdx) {
        if (inputJackIdx >= this.numJacks) {
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
        new IOBox(numIns, IOType.OUTPUT, 2.) @=> this.nodeOutputsBox;
        this.nodeOutputsBox --> this;
    }
}
