@import {"../events.ck", "../utils.ck"}
@import "base.ck"
@import "HashMap"


public class ComposeNode extends Node {
    fun @construct() {
        ComposeNode(1, 4.);
    }

    fun @construct(int numStartButtons) {
        ComposeNode(numStartButtons, 4.);
    }

    fun @construct(int numStartButtons, float xScale) {
        // Set node ID and name
        "Compose Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Compose", xScale) @=> this.nodeNameBox;

        // Create button box
        new IOModifierBox(xScale) @=> this.nodeButtonModifierBox;
        new ButtonBox(numStartButtons, xScale) @=> this.nodeButtonBox;

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeButtonModifierBox --> this;
        this.nodeButtonBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        // Button data
        data.set("numButtons", this.nodeButtonBox.buttons.size());

        return data;
    }
}
