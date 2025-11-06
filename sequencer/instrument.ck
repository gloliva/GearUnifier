@import "../tuning/base.ck"
@import "smuck"


public class ComposerInstrument extends ezInstrument {
    // Tuning
    Tuning @ tuning;

    // Outputs
    Step pitch(0.);
    Step gate(0.);
    Step envOut(0.);
    Envelope env;

    fun @construct(Tuning tuning) {
        this.env => blackhole;
        this.setTuning(tuning);
        this.numVoices(1);
        spork ~ updateOut(); // TODO: Fix this by removing this shred when ComposerNode is removed
    }

    fun void setTuning(Tuning tuning) {
        tuning @=> this.tuning;
    }

    fun void noteOn(ezNote note, int voice) {
        // Extract data
        note.data() @=> float data[];
        data[0]$int => int octave;
        data[1]::samp => dur attackTime;
        data[2]::samp => dur decayTime;
        data[3]::samp => dur releaseTime;
        data[4] => float releaseLevel;

        // Set pitch
        this.tuning.cv(note.pitch()$int, octave) => this.pitch.next;

        // Set note gate
        1. => this.gate.next;

        // Trigger Envelope
        spork ~ this.triggerEnvelope(attackTime, decayTime, note.velocity(), releaseTime, releaseLevel);
    }

    fun void noteOff(ezNote note, int voice) {
        0. => this.gate.next;
    }

    fun void triggerEnvelope(dur attackTime, dur decayTime, float sustainLevel, dur releaseTime, float releaseLevel) {
        // Attack
        this.env.ramp(attackTime, sustainLevel);
        attackTime => now;

        this.env.ramp(releaseTime, releaseLevel);
        releaseTime => now;
    }

    fun void updateOut() {
        while (true) {
            this.env.value() => this.envOut.next;
            10::ms => now;
        }
    }
}
