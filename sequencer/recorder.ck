@import "../utils.ck"
@import "base.ck"


public class MidiRecorder {
    // Sequence
    Sequence @ sequence;

    // On/Off
    Gate gate;

    // Timer
    time stopwatch;

    fun void on() {
        1 => this.gate.on;
        new Sequence @=> this.sequence;
        now => this.stopwatch;
    }

    fun Sequence off() {
        0 => this.gate.on;
        this.sequence @=> Sequence recordedSequence;
        null => this.sequence;
        return recordedSequence;
    }

    fun int isRecording() {
        return this.gate.on;
    }

    fun void recordMsg(MidiMsg msg) {
        if (this.sequence == null) {
            <<< "ERROR: sequence is not set in MidiRecorder.recordMsg. Please call MidiRecorder.on()" >>>;
            return;
        }

        now - this.stopwatch => dur timeSinceLast;
        now => this.stopwatch;

        MidiRecord record(msg, timeSinceLast);
        this.sequence.addRecord(record);
    }
}
