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
