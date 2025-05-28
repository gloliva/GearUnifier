public class Enum {
    int id;
    string name;

    fun @construct(int id, string name) {
        id => this.id;
        name => this.name;
    }
}


public class Gate {
    int on;

    fun @construct(int startOn) {
        startOn => this.on;
    }
}
