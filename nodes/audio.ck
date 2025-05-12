// Imports
@import "base.ck"


public class AudioNode extends Node {
    // Audio Nodes do their own content box and Jacks handling
    GCube contentBox;
    Jack jacks[0];

    string ioType;

    fun @construct(int type, int numJacks) {
        // Member variables
        numJacks => this.numJacks;
        IOType.toString(type) => this.ioType;

        // Node name box
        new NameBox("Audio " + this.ioType, 2., 1.) @=> this.nodeNameBox;

        // Position
        0.5 - (this.numJacks / 2.) => this.contentBox.posY;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;
        @(2., this.numJacks, 0.2) => this.contentBox.sca;

        // Color
        Color.GRAY => this.contentBox.color;

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
        this.nodeNameBox --> this;
        this.contentBox --> this;
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
