public class AddNodeEvent extends Event {
    int nodeType;
    string menuName;
    int menuIdx;

    fun void set(int type, string name, int idx) {
        type => this.nodeType;
        name => this.menuName;
        idx => this.menuIdx;
    }
}


public class SaveLoadEvent extends Event {
    int mode;

    fun void set(int mode) {
        mode => this.mode;
    }
}


public class ButtonClicked extends Event {}


public class UpdateNumberEntryBoxEvent extends Event {
    int numberBoxIdx;
    int numberBoxValue;
    float numberBoxFloatValue;

    fun void set(int numberBoxIdx, int numberBoxValue, float numberBoxFloatValue) {
        numberBoxIdx => this.numberBoxIdx;
        numberBoxValue => this.numberBoxValue;
        numberBoxFloatValue => this.numberBoxFloatValue;
    }
}


public class UpdateTextEntryBoxEvent extends Event {
    string text;
    int mode;

    fun void set(string text, int mode) {
        text => this.text;
        mode => this.mode;
    }
}


public class MoveCameraEvent extends Event {
    float translateX;
    float translateY;

    fun void set(float x, float y) {
        x => this.translateX;
        y => this.translateY;
    }
}
