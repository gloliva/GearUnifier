public class MidiRecord {
    int data1;
    int data2;
    int data3;
    dur timeSinceLast;

    fun @construct(MidiMsg msg, dur timeSinceLast) {
        msg.data1 => this.data1;
        msg.data2 => this.data2;
        msg.data3 => this.data3;
        timeSinceLast => this.timeSinceLast;
    }

    fun @construct(int data1, int data2, int data3, dur timeSinceLast) {
        data1 => this.data1;
        data2 => this.data2;
        data3 => this.data3;
        timeSinceLast => this.timeSinceLast;
    }
}


public class Sequence {
    MidiRecord records[0];

    fun void addRecord(MidiRecord record) {
        this.records << record;
    }

    fun MidiRecord[] getRecords() {
        return this.records;
    }

    fun void print() {
        for (MidiRecord record : this.records) {
            chout <= record.data1 <= " " <= record.data2 <= " " <= record.data3 <= " " <= record.timeSinceLast / 1::samp <= IO.nl();
        }
    }
}
