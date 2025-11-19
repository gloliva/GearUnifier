@import "../tuning/base.ck"
@import "Line"
@import "smuck"


public class ComposerInstrument extends ezInstrument {
    // Tuning
    Tuning @ tuning;

    // Outputs
    Step pitch(0.);
    Step gate(0.);
    Step env(0.);
    Line line;

    // Envelope Handling
    0 => int inNoteOnPhase;

    // Shreds
    Shred @ envUpdateShred;

    fun @construct(Tuning tuning) {
        this.line => blackhole;
        this.setTuning(tuning);
        this.numVoices(1);
        spork ~ updateOut() @=> this.envUpdateShred;
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
        <<< "Pitch", note.pitch(), "Octave", octave, "CV", this.tuning.cv(note.pitch()$int, octave) >>>;
        this.tuning.cv(note.pitch()$int, octave) => this.pitch.next;

        // Set note gate
        1. => this.gate.next;

        // // Trigger Envelope
        // spork ~ this.triggerAttack(attackTime, decayTime, note.velocity());
        1 => this.inNoteOnPhase;
        this.line.keyOn(note.velocity(), attackTime) => now;
        // this.line.keyOn(releaseLevel, releaseTime) => now;
        0 => this.inNoteOnPhase;
    }

    fun void noteOff(ezNote note, int voice) {
        // Turn gate off
        0. => this.gate.next;

        // Extract data
        note.data() @=> float data[];
        if (data.size() < 5) {
            <<< "Not enough data to extract, data size is", data.size(), "turning note off" >>>;
            // this.triggerRelease(0::second, 0.);
            return;
        }

        data[0]$int => int octave;
        data[1]::samp => dur attackTime;
        data[2]::samp => dur decayTime;
        data[3]::samp => dur releaseTime;
        data[4] => float releaseLevel;


        <<< "Pitch OFF", note.pitch(), "Release time", releaseTime, "Release level", releaseLevel >>>;

        // Trigger Envelope
        if (!this.inNoteOnPhase) {
            this.triggerRelease(releaseTime, releaseLevel);
        }
    }

    fun void triggerAttack(dur attackTime, dur decayTime, float sustainLevel) {
        // Attack
        this.line.keyOn(sustainLevel, attackTime) => now;
        // attackTime => now;
    }

    fun void triggerRelease(dur releaseTime, float releaseLevel) {
        <<< "Release env", releaseTime, releaseLevel >>>;
        this.line.keyOn(releaseLevel, releaseTime) => now;
        <<< "End of release" >>>;
    }

    fun void updateOut() {
        while (true) {
            this.line.last() => this.env.next;
            1::ms => now;
        }
    }
}
