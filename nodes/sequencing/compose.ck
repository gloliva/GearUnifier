@import {"../../events.ck", "../../utils.ck"}
@import "../../sequencer/composer.ck"
@import "../../ui/composeBox.ck"
@import "../base.ck"
@import "HashMap"


public class ComposeNode extends Node {
    ComposeBox composeBoxes[0];

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

        // Add compose boxes
        for (int idx; idx < numStartButtons; idx++) {
            ComposeBox composeBox("Scene " + (idx + 1), 13, 13);
            composeBox.setID(this.nodeID + " " + composeBox.headerName);
            this.composeBoxes << composeBox;
        }

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

    fun void addButton() {
        this.nodeButtonBox.addButton();
        ComposeBox composeBox("Scene " + (this.composeBoxes.size() + 1), 13, 13);
        composeBox.setID(this.nodeID + " " + composeBox.headerName);
        this.composeBoxes << composeBox;
    }

    fun void removeButton() {
        this.nodeButtonBox.removeButton();
        this.composeBoxes.popBack();
    }

    fun void handleButtonPress(int buttonIdx) {
        this.composeBoxes[buttonIdx] @=> ComposeBox currComposeBox;

        if (!currComposeBox.active) {
            1 => currComposeBox.active;
        } else {
            0 => currComposeBox.active;
        }
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        // Button data
        data.set("numButtons", this.nodeButtonBox.buttons.size());

        return data;
    }
}
