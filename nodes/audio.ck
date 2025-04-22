// Imports
@import "base.ck"


public class AudioNode extends Node {
    string ioType;

    fun @construct(int type, int numJacks) {
        // Parent constructor
        Node();

        // Member variables
        numJacks => this.numJacks;

        // Position
        @(0., 1., 0.101) => this.nodeName.pos;
        1. => this.nodeNameBox.posY;
        0.5 - (this.numJacks / 2.) => this.nodeContentBox.posY;
        // (numJacks / 2.) - 0.25 => this.posY;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;
        @(0.25, 0.25, 0.25) => this.nodeName.sca;
        @(2., 1., 0.2) => this.nodeNameBox.sca;
        @(2., this.numJacks, 0.2) => this.nodeContentBox.sca;

        // Text
        IOType.toString(type) => this.ioType;
        "Audio " + this.ioType => this.nodeName.text;

        // Color
        @(3., 3., 3., 1.) => this.nodeName.color;
        Color.BLACK => this.nodeNameBox.color;
        Color.GRAY => this.nodeContentBox.color;

        // Handle Jacks
        IOType.INPUT => int jackType;
        if (type == IOType.INPUT) {
            IOType.OUTPUT => jackType;
        }

        for (int idx; idx < numJacks; idx++) {
            Jack jack(idx, jackType);

            // Jack Position
            idx * -1. => jack.posY;

            // Jack Connection
            jack --> this;
            this.jacks << jack;
        }

        // Names
        "Audio " + this.ioType + " Node" => this.name;

        // Set ID
        Std.itoa(Math.random()) => string randomID;
        this.name() + " ID " + randomID => this.nodeID;

        // Connections
        this.nodeName --> this;
        this.nodeNameBox --> this;
        this.nodeContentBox --> this;
    }
}


public class AudioOutNode extends AudioNode {
    fun @construct(int numOuts) {
        AudioNode(IOType.OUTPUT, numOuts);
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
        AudioNode(IOType.INPUT, numIns);
    }
}
