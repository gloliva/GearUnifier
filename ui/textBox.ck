@import "base.ck"
@import "../events.ck"


public class NumberBoxType {
    0 => static int INT;
    1 => static int FLOAT;
}


public class NumberEntryBox extends GGen {
    // Contents
    BorderedBox @ box;

    // Index
    int numberBoxIdx;

    // Number
    string numberChars;
    int charLimit;
    int numberType;

    // Event
    UpdateNumberEntryBoxEvent @ updateEvent;

    // Visibility
    int active;

    fun @construct(int numberBoxIdx) {
        numberBoxIdx => this.numberBoxIdx;
        NumberEntryBox(3, numberBoxIdx, NumberBoxType.INT);
    }

    fun @construct(int charLimit, int numberBoxIdx) {
        numberBoxIdx => this.numberBoxIdx;
        NumberEntryBox(charLimit, numberBoxIdx, NumberBoxType.INT);
    }

    fun @construct(int charLimit, int numberBoxIdx, int numberType) {
        NumberEntryBox(charLimit, numberBoxIdx, numberType, 1.);
    }

    fun @construct(int charLimit, int numberBoxIdx, int numberType, float xScale) {
        charLimit => this.charLimit;
        numberBoxIdx => this.numberBoxIdx;

        BorderedBox box("0", xScale, 0.5);
        box @=> this.box;

        // Names
        "Number Entry Box" => this.name;
        "Box" => this.box.name;

        // Connections
        this.box --> this;
    }

    fun void set(int number) {
        Std.itoa(number) => string numberStr;
        Math.min(numberStr.length(), this.charLimit) => int limit;

        numberStr.substring(0, limit) => this.numberChars;
        this.box.setName(this.numberChars);
    }

    fun void set(float number) {
        Std.ftoa(number, 2) => string numberStr;
        Math.min(numberStr.length(), this.charLimit) => int limit;

        numberStr.substring(0, limit) => this.numberChars;
        this.box.setName(this.numberChars);
    }

    fun int getInt() {
        if (this.numberChars.length() == 0) {
            return 0;
        }

        if (this.numberChars.length() == 0 && (this.numberChars == "-" || this.numberChars == ".")) return 0;

        return Std.atoi(this.numberChars);
    }

    fun float getFloat() {
        if (this.numberChars.length() == 0) {
            return 0.;
        }

        if (this.numberChars.length() == 0 && (this.numberChars == "-" || this.numberChars == ".")) return 0.;

        return Std.atof(this.numberChars);
    }

    fun void addSpecialChar(string char) {
        if (this.numberChars.length() >= this.charLimit) return;

        if ((this.numberChars.length() == 0 && char == "-") || char == ".") {
            this.numberChars + char => this.numberChars;
            this.box.setName(this.numberChars);
        }
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

        if (this.numberChars.length() == 0) {
            this.box.setName("0");
        }
    }

    fun void setUpdateEvent(UpdateNumberEntryBoxEvent updateEvent) {
        updateEvent @=> this.updateEvent;
    }

    fun void signalUpdate() {
        if (this.updateEvent != null) {
            this.updateEvent.set(this.numberBoxIdx, this.getInt(), this.getFloat());
            this.updateEvent.broadcast();
        }
    }
}


public class TextEntryBox extends GGen {
    // Contents
    BorderedBox @ box;

    // Number
    string chars;
    int charLimit;

    // Event
    UpdateTextEntryBoxEvent @ updateEvent;

    // Visibility
    int active;

    fun @construct(int charLimit, float xScale) {
        charLimit => this.charLimit;

        BorderedBox box("Enter Filename Here", xScale, 0.5);
        box @=> this.box;

        // Names
        "Number Entry Box" => this.name;
        "Box" => this.box.name;

        // Connections
        this.box --> this;
    }

    fun void set(string s) {
        Math.min(s.length(), this.charLimit) => int limit;

        s.substring(0, limit) => this.chars;
        this.box.setName(this.chars);
    }

    fun void addChar(string char) {
        if (this.chars.length() >= this.charLimit) return;
        this.chars + char => this.chars;

        // Update box
        this.box.setName(this.chars);
    }

    fun void addChar(int char) {
        if (this.chars.length() >= this.charLimit) return;
        this.chars.appendChar(char);

        // Update box
        this.box.setName(this.chars);
    }

    fun void removeChar() {
        if (this.chars.length() == 0) return;

        this.chars.substring(0, this.chars.length() - 1) => this.chars;

        // Update box
        this.box.setName(this.chars);

        if (this.chars.length() == 0) {
            this.box.setName("Enter Filename Here");
        }
    }

    fun void setUpdateEvent(UpdateTextEntryBoxEvent updateEvent) {
        updateEvent @=> this.updateEvent;
    }

    fun void signalUpdate(int state) {
        if (this.updateEvent != null && this.chars.length() > 0) {
            this.updateEvent.set(this.chars, state);
            this.updateEvent.broadcast();
        }
    }
}
