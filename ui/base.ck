@import "../events.ck"


public class BorderedBox extends GGen {
    GCube box;
    GText text;

    GCube leftBorder;
    GCube rightBorder;
    GCube topBorder;
    GCube bottomBorder;

    fun @construct() {
        BorderedBox("------");
    }

    fun @construct(string nameText) {
        BorderedBox(nameText, 2., 0.5);
    }

    fun @construct(string nameText, float xScale, float yScale) {
        // Scale and Position
        this.setScale(xScale, yScale);

        // Text
        nameText => this.text.text;

        // Color
        Color.GRAY => this.box.color;
        @(3., 3., 3., 1.) => this.text.color;

        Color.BLACK => this.leftBorder.color;
        Color.BLACK => this.rightBorder.color;
        Color.BLACK => this.topBorder.color;
        Color.BLACK => this.bottomBorder.color;

        // Names
        "Bordered Box" => this.name;
        "Box" => this.box.name;
        "Name" => this.text.name;

        "Left Border" => this.leftBorder.name;
        "Right Border" => this.rightBorder.name;
        "Top Border" => this.topBorder.name;
        "Bottom Border" => this.bottomBorder.name;

        // Connections
        this.box --> this;
        this.text --> this;

        this.leftBorder --> this;
        this.rightBorder --> this;
        this.topBorder --> this;
        this.bottomBorder --> this;
    }

    fun void setScale(float xScale, float yScale) {
        // Scale
        @(xScale, yScale, 0.2) => this.box.sca;
        @(0.25, 0.25, 0.25) => this.text.sca;

        @(0.05, yScale, 0.2) => this.leftBorder.sca;
        @(0.05, yScale, 0.2) => this.rightBorder.sca;
        @(xScale, 0.05, 0.2) => this.topBorder.sca;
        @(xScale, 0.05, 0.2) => this.bottomBorder.sca;

        // Position
        0.101 => this.text.posZ;

        (xScale / 2.) - (this.leftBorder.scaX() / 2.) => float xBorderPos;
        (yScale / 2.) - (this.topBorder.scaY() / 2.) => float yBorderPos;

        @(-xBorderPos, 0., 0.001) => this.leftBorder.pos;
        @(xBorderPos, 0., 0.001) => this.rightBorder.pos;
        @(0., yBorderPos, 0.001) => this.topBorder.pos;
        @(0., -yBorderPos, 0.001) => this.bottomBorder.pos;
    }

    fun void setName(string n) {
        n => this.text.text;
    }
}


public class Button extends BorderedBox {
    ButtonClicked clickEvent;

    fun @construct(string nameText, float xScale, float yScale) {
        BorderedBox(nameText, xScale, yScale);

        // Names
        "Button" => this.name;
    }

    fun void clickOn() {
        Color.DARKGRAY => this.box.color;
        this.clickEvent.broadcast();
    }

    fun void clickOff() {
        Color.GRAY => this.box.color;
    }
}
