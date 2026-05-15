@import {"../../events.ck", "../../utils.ck"}
@import "../../ui/textBox.ck"
@import "../base.ck"
@import "HashMap"


public class MouseOutputType {
    new Enum(0, "Mouse X") @=> static Enum MOUSE_X;
    new Enum(1, "Mouse Y") @=> static Enum MOUSE_Y;
    new Enum(2, "Left Click") @=> static Enum LEFT_CLICK;
    new Enum(3, "Wheel") @=> static Enum MOUSE_WHEEL;

    [
        MouseOutputType.MOUSE_X,
        MouseOutputType.MOUSE_Y,
        MouseOutputType.LEFT_CLICK,
        MouseOutputType.MOUSE_WHEEL,
    ] @=> static Enum allTypes[];
}


public class MouseNode extends Node {
    // HID objects
    Hid mouse;
    HidMsg msg;

    // Mouse Wheel
    float wheelPos;
    0.05 => float wheelDelta;

    // Check if mouse can be opened
    int good;

    fun @construct(int device) {
        MouseNode(device, 4.);
    }

    fun @construct(int device, float xScale) {
        // Setup mouse
        if (!this.mouse.openMouse(device)) return;
        1 => this.good;

        // Set node ID and name
        this.mouse.name() + "-Mouse-Node" => this.name;
        this.setNodeID();

        // Node name box
        new NameBox("Mouse", xScale) @=> this.nodeNameBox;

        // Create outputs box
        MouseOutputType.allTypes @=> this.outputTypes;
        new IOBox(this.outputTypes.size(), MouseOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        for (int outIdx; outIdx < MouseOutputType.allTypes.size(); outIdx++) {
            this.nodeOutputsBox.setOutput(MouseOutputType.allTypes[outIdx], outIdx);
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
        spork ~ this.processMouse() @=> Shred @ processMouseShred;
        this.addShreds([processMouseShred]);
    }

    fun void processMouse() {
        while( true ) {
            // wait on HidIn as event
            this.mouse => now;

            // messages received
            while( this.mouse.recv( this.msg ) ) {
                // mouse motion
                if( this.msg.isMouseMotion() ) {
                    Math.clampf(this.msg.scaledCursorX, 0., 1.) => this.nodeOutputsBox.outs(MouseOutputType.MOUSE_X).next;
                    Math.clampf(this.msg.scaledCursorY, 0., 1.) => this.nodeOutputsBox.outs(MouseOutputType.MOUSE_Y).next;
                }

                // Mouse button click
                if( this.msg.isButtonDown() ) {
                    1. => this.nodeOutputsBox.outs(MouseOutputType.LEFT_CLICK).next;
                } else if( this.msg.isButtonUp() ) {
                    0. => this.nodeOutputsBox.outs(MouseOutputType.LEFT_CLICK).next;
                }

                // mouse wheel motion
                if(this. msg.isWheelMotion() && this.msg.deltaY ) {
                    Math.clampf((this.msg.deltaY * this.wheelDelta) + this.wheelPos, -1., 1.) => this.wheelPos;
                    this.wheelPos => this.nodeOutputsBox.outs(MouseOutputType.MOUSE_WHEEL).next;
                }
            }
        }
    }

    fun HashMap serialize() {
        super.serialize() @=> HashMap data;

        data.set("deviceId", this.mouse.num());
        data.set("deviceName", this.mouse.name());

        return data;
    }
}
