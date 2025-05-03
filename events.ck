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
