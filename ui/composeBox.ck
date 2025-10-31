@import "base.ck"
@import {"../base.ck", "../events.ck"}


public class ComposeBox extends ClickableGGen {
    // Contents
    BorderedBox @ header;
    BorderedBox @ close;
    BorderedBox @ contentBorder;
    BorderedBox @ contentBox;

    // Text Handling
    GText lineNumbers[0];
    GText lines[0];

    // Parameters
    string ID;
    string headerName;
    int active;

    fun @construct(string headerName, float xScale, float yScale) {
        headerName => this.headerName;

        // Create content boxes
        new BorderedBox(headerName, Color.BLACK, xScale, 1.) @=> this.header;
        new BorderedBox("x", Color.RED, 0.5, 0.5) @=> this.close;
        new BorderedBox("", xScale, yScale) @=> this.contentBorder;
        new BorderedBox("", Color.LIGHTGRAY, xScale - 1, yScale - 1) @=> this.contentBox;

        // Position
        (this.header.box.scaY() / 2.) + (this.contentBorder.box.scaY() / 2.) - this.header.bottomBorder.scaY() => float yPos;
        yPos => this.header.posY;
        yPos => this.close.posY;
        (this.header.box.scaX() / 2.) - (this.close.scaX() / 2.) => this.close.posX;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Handle first line text
        GText firstLineNumber;
        "1" => firstLineNumber.text;
        0.11 => firstLineNumber.posZ;
        @(0.5, 0.5, 1.) => firstLineNumber.sca;
        Color.BLACK => firstLineNumber.color;
        this.lineNumbers << firstLineNumber;
        firstLineNumber --> this;

        GText firstLine;
        "" => firstLine.text;
        0.11 => firstLine.posZ;
        @(0.5, 0.5, 1.) => firstLine.sca;
        Color.BLACK => firstLine.color;
        this.lineNumbers << firstLine;
        firstLine --> this;

        // Names
        "Header Box" => this.header.name;
        "Close Box" => this.close.name;
        "Content Border" => this.contentBorder.name;
        "Content Box" => this.contentBox.name;

        // Connections
        this.header --> this;
        this.close --> this;
        this.contentBorder --> this;
        this.contentBox --> this;
    }

    fun void setID(string id) {
        id => this.ID;
    }

    fun int mouseOverComposeBox(vec3 mouseWorldPos) {
        false => int mouseIsOver;

        this.mouseOverHeader(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverContentBorder(mouseWorldPos) || mouseIsOver => mouseIsOver;

        return mouseIsOver;

    }

    fun int mouseOverHeader(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.header, this.header.box]);
    }

    fun int mouseOverClose(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.close, this.close.box]);
    }

    fun int mouseOverContentBorder(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.contentBorder, this.contentBorder.box]);
    }

    fun int mouseOverContentBox(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.contentBox, this.contentBox.box]);
    }
}
