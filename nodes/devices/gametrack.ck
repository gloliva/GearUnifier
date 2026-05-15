@import {"../../events.ck", "../../utils.ck"}
@import "../../ui/textBox.ck"
@import "../base.ck"
@import "HashMap"


public class GametrakInputType {

}


public class GametrakOutputType {
    new Enum(0, "Left X") @=> static Enum AXIS_1;
    new Enum(1, "Left Y") @=> static Enum AXIS_2;
    new Enum(2, "Left Z") @=> static Enum AXIS_3;
    new Enum(3, "Right X") @=> static Enum AXIS_4;
    new Enum(4, "Right Y") @=> static Enum AXIS_5;
    new Enum(5, "Right Z") @=> static Enum AXIS_6;
    new Enum(6, "Button") @=> static Enum BUTTON;

    [
        GametrakOutputType.AXIS_1,
        GametrakOutputType.AXIS_2,
        GametrakOutputType.AXIS_3,
        GametrakOutputType.AXIS_4,
        GametrakOutputType.AXIS_5,
        GametrakOutputType.AXIS_6,
        GametrakOutputType.BUTTON,
    ] @=> static Enum allTypes[];
}


public class GameTrakNode extends Node {
    6 => static int NUM_AXES;

    // HID objects
    Hid gt;
    HidMsg msg;

    // Deadzone for Z axis
    float deadzones[2];

    // Check if GameTrak can be opened
    int good;

    fun @construct(int device) {
        GameTrakNode(device, .04, 4.);
    }

    fun @construct(int device, float deadzone, float xScale) {
        // Setup GameTrak
        if (!this.gt.openJoystick(device)) return;
        1 => this.good;
        deadzone => this.deadzones[0] => this.deadzones[1];

        // Set node ID and name
        "GameTrak-Node" => this.name;
        this.setNodeID();

        // Node name box
        new NameBox("GameTrak", xScale) @=> this.nodeNameBox;

        // Create outputs box
        GametrakOutputType.allTypes @=> this.outputTypes;
        new IOBox(7, GametrakOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        for (int outIdx; outIdx < GametrakOutputType.allTypes.size(); outIdx++) {
            this.nodeOutputsBox.setOutput(GametrakOutputType.allTypes[outIdx], outIdx);
        }

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();

        // Shreds
        spork ~ this.processGameTrak() @=> Shred @ processGameTrakShred;
        this.addShreds([processGameTrakShred]);
    }

    fun void processGameTrak() {
        while (true) {
            // wait on HidIn as event
            this.gt => now;

            // messages received
            while (this.gt.recv(this.msg)) {
                // joystick axis motion
                if (this.msg.isAxisMotion()) {
                    // check which
                    if (this.msg.which >= 0 && this.msg.which < this.NUM_AXES) {
                        GametrakOutputType.allTypes[this.msg.which] @=> Enum axis;

                        // the z axes map to [0,1], others map to [-1,1]
                        if (this.msg.which != 2 && this.msg.which != 5) {
                            this.msg.axisPosition => this.nodeOutputsBox.outs(axis).next;
                        }
                        else {
                            this.deadzones[0] => float deadzone;
                            if (this.msg.which == GametrakOutputType.AXIS_6.id) {
                                this.deadzones[1] => deadzone;
                            }
                            Math.clampf((1 - ((this.msg.axisPosition + 1) / 2) - deadzone), 0., 1.) => this.nodeOutputsBox.outs(axis).next;
                        }
                    }
                }

                // Handle button presses
                if (this.msg.isButtonDown()) {
                    1. => this.nodeOutputsBox.outs(GametrakOutputType.BUTTON).next;
                } else if (msg.isButtonUp()) {
                    0. => this.nodeOutputsBox.outs(GametrakOutputType.BUTTON).next;
                }
            }
        }
    }

    fun HashMap serialize() {
        super.serialize() @=> HashMap data;

        data.set("deviceId", this.gt.num());
        data.set("deviceName", this.gt.name());

        return data;
    }
}
