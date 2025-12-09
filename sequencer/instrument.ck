@import "../tuning/base.ck"
@import "base.ck"
@import "smuck"


public class ComposerInstrument extends ezInstrument {
    /*

    ComposerInstrument is a monophonic instrument for Eurorack oscillators.
    ezNotes pitch corresponds to the scale degree of the current tuning.
    ezNotes must contain extra data to handle octave and envelope information.

    ezNote data format:

    0) Octave number [integer]
    1) Number of Envelope pairs [integer]
    2) EnvPair1 rhythm type [int]
    3) EnvPair1 ramp time [duration]
    4) EnvPair1 ramp value [float]
    5) EnvPair2 rhythm type [int]
    6) EnvPair2 ramp time [duration]
    7) EnvPair2 ramp value [float]
    ...
    numPairs * 2) EnvPairN ramp time [duration]
    (numPairs * 2) + 1) EnvPairN ramp value [float]

    The last Envelope pair is the ReleaseTime and ReleaseValue, and used during the noteOff phase.
    All other Envelope pairs are handled during the noteOn phase.

    */

    // Score Player
    ezScorePlayer @ scorePlayer;

    // Tuning
    Tuning @ tuning;

    // Outputs
    Step pitch(0.);
    Step gate(0.);
    Step env(0.);
    Envelope line;

    // Envelope Handling
    string activeNote;

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

    fun void setScorePlayer(ezScorePlayer scorePlayer) {
        scorePlayer @=> this.scorePlayer;
    }

    fun void noteOn(ezNote note, int voice) {
        // Extract data
        note.data() @=> float data[];
        data[0]$int => int octave;
        data[1]$int => int numEnvPairs;

        EnvelopePair envPairs[0];
        for (int pair; pair < numEnvPairs; pair++) {
            2 + (pair * 3) => int typeIdx;
            2 + (pair * 3) + 1 => int timeIdx;
            2 + (pair * 3) + 2 => int valueIdx;

            data[typeIdx]$int => int rhythmType;
            if (rhythmType == RhythmType.SMUCKISH) {
                envPairs << new EnvelopePair(data[timeIdx], data[valueIdx]);
            } else if (rhythmType == RhythmType.DURATION) {
                envPairs << new EnvelopePair(data[timeIdx]::samp, data[valueIdx]);
            }
        }

        // Set pitch
        <<< "Pitch", note.pitch(), "Octave", octave, "CV", this.tuning.cv(note.pitch()$int, octave) >>>;
        this.tuning.cv(note.pitch()$int, octave) => this.pitch.next;

        // Set note gate
        1. => this.gate.next;

        // Set active note
        Std.itoa(note.pitch()$int) + Std.itoa(octave) => this.activeNote;

        // Trigger Envelope(s)
        for (int envIdx; envIdx < envPairs.size() - 1; envIdx++) {
            envPairs[envIdx] @=> EnvelopePair pair;

            if (pair.rhythmType == RhythmType.SMUCKISH) {
                ((60000. / this.scorePlayer.bpm()) * pair.numBeats)::ms => dur rampTime;
                this.line.ramp(rampTime, pair.rampValue) => now;
            } else if (pair.rhythmType == RhythmType.DURATION) {
                this.line.ramp(pair.rampTime, pair.rampValue) => now;
            }
        }
    }

    fun void noteOff(ezNote note, int voice) {
        // Turn gate off
        0. => this.gate.next;

        // Check if data exists
        note.data() @=> float data[];
        if (data.size() < 5) {
            <<< "Not enough data to extract, data size is", data.size(), "turning note off" >>>;
            this.line.ramp(0::second, 0.);
            return;
        }

        // Extract data
        data[0]$int => int octave;
        data[1]$int => int numEnvPairs;

        // Trigger Envelope
        Std.itoa(note.pitch()$int) + Std.itoa(octave) => string currNote;
        if (currNote == this.activeNote) {
            data[-3]$int => int rhythmType;
            data[-1] => float rampValue;
            if (rhythmType == RhythmType.SMUCKISH) {
                ((60000. / this.scorePlayer.bpm()) * data[-2])::ms => dur rampTime;
                this.line.ramp(rampTime, rampValue) => now;
            } else if (rhythmType == RhythmType.DURATION) {
                this.line.ramp(data[-2]::samp, rampValue) => now;
            }
        }
    }

    fun void updateOut() {
        while (true) {
            this.line.value() => this.env.next;
            1::ms => now;
        }
    }
}
