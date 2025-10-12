@import "base.ck"
@import {"../base.ck", "../events.ck"}


public class PopupMenu extends ClickableGGen {
    // Contents
    BorderedBox @ box;
    Button @ button;

    int closed;

    fun @construct(string popupText, float xScale, float yScale) {
        new BorderedBox(popupText, xScale, yScale) @=> this.box;
        new Button("Close", 0.5, 0.25) @=> this.button;

        // Text
        xScale - (0.1 * xScale) => float alignment;
        <<< "Text alignment", alignment >>>;
        this.box.text.maxWidth(25);  // TODO: figure out a way to calculate this
        this.box.text.align(1);

        // Pos
        -0.75 => this.button.posY;

        // Scale
        @(0.15, 0.15, 0.15) => this.box.text.sca;
        @(0.1, 0.1, 0.1) => this.button.text.sca;

        // Names
        "Popup Menu" => this.name;
        "Box" => this.box.name;

        // Connections
        this.box --> this;
        this.button --> this;
    }

    fun void openAndWait() {
        this.open();
        this.button.clickEvent => now;
        1 => this.closed;
    }

    fun void open() {
        0 => this.closed;
        this --> GG.scene();
    }

    fun void close() {
        this --< GG.scene();
    }

    fun int mouseOverButton(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.button, this.button.box]);
    }
}
