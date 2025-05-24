@import "base.ck"

public class NumberEntryBox extends GGen {
    // Contents
    BorderedBox @ box;

    // Number
    string numberChars;
    int charLimit;

    // Visibility
    int active;

    fun @construct() {
        NumberEntryBox(3);
    }

    fun @construct(int charLimit) {
        charLimit => this.charLimit;

        BorderedBox box("0", 1., 0.5);
        box @=> this.box;

        // Names
        "Number Entry Box" => this.name;
        "Box" => this.box.name;

        // Connections
        this.box --> this;
    }

    fun int getNumber() {
        if (this.numberChars.length() == 0) {
            return -1;
        }

        return Std.atoi(this.numberChars);
    }

    fun void addNumberChar(int number) {
        if (this.numberChars.length() >= this.charLimit) return;

        if (number < 0 || number > 9) {
            <<< "ERROR: Number must be between 0 and 9" >>>;
            return;
        }

        this.numberChars + Std.itoa(number) => this.numberChars;

        // Update box
        this.box.setName(this.numberChars);
    }

    fun void removeNumberChar() {
        if (this.numberChars.length() == 0) return;

        this.numberChars.substring(0, this.numberChars.length() - 1) => this.numberChars;

        // Update box
        this.box.setName(this.numberChars);
    }
}
