@import "base.ck"
@import "../events.ck"

public class NumberEntryBox extends GGen {
    // Contents
    BorderedBox @ box;

    // Index
    int numberBoxIdx;

    // Number
    string numberChars;
    int charLimit;

    // Event
    UpdateNumberEntryBoxEvent @ updateEvent;

    // Visibility
    int active;

    fun @construct(int numberBoxIdx) {
        numberBoxIdx => this.numberBoxIdx;
        NumberEntryBox(3, numberBoxIdx);
    }

    fun @construct(int charLimit, int numberBoxIdx) {
        charLimit => this.charLimit;
        numberBoxIdx => this.numberBoxIdx;

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
        <<< "Number chars length", this.numberChars.length() >>>;

        // Update box
        this.box.setName(this.numberChars);
    }

    fun void removeNumberChar() {
        if (this.numberChars.length() == 0) return;

        this.numberChars.substring(0, this.numberChars.length() - 1) => this.numberChars;

        // Update box
        this.box.setName(this.numberChars);

        if (this.numberChars.length() == 0) {
            this.box.setName("0");
        }
    }

    fun void setUpdateEvent(UpdateNumberEntryBoxEvent updateEvent) {
        updateEvent @=> this.updateEvent;
    }

    fun void signalUpdate() {
        if (this.updateEvent != null) {
            this.updateEvent.set(this.numberBoxIdx, this.getNumber());
            this.updateEvent.broadcast();
        }
    }
}
