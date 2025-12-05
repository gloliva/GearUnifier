@import "../../utils.ck"
@import "../base.ck"
@import "HashMap"
@import "smuck"


public class ScorePlayerInputType {
    new Enum(0, "Play/Pause") @=> static Enum RUN;
    new Enum(1, "Stop") @=> static Enum STOP;
    new Enum(2, "Rate") @=> static Enum RATE;
    new Enum(3, "Loop") @=> static Enum LOOP;

    [
        ScorePlayerInputType.RUN,
        ScorePlayerInputType.STOP,
        ScorePlayerInputType.RATE,
        ScorePlayerInputType.LOOP,
    ] @=> static Enum allTypes[];
}


public class ScorePlayerOutputType {
    new Enum(0, "Player") @=> static Enum PLAYER;

    [
        ScorePlayerOutputType.PLAYER,
    ] @=> static Enum allTypes[];
}


public class ScorePlayerNode extends Node {
    ezPart partsMap[0];
    ezInstrument instrumentMap[0];
    ezScore score;
    ezScorePlayer scorePlayer;

    // State management
    0 => int isPlaying;
    0 => int isStopped;

    fun @construct() {
        ScorePlayerNode(4.);
    }

    fun @construct(float xScale) {
        // Set node ID and name
        "ScorePlayer Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("ScorePlayer", xScale) @=> this.nodeNameBox;

        // Create inputs box
        ScorePlayerInputType.allTypes @=> this.inputTypes;
        new IOModifierBox(xScale) @=> this.nodeInputsModifierBox;
        new IOBox(2, this.inputTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        this.nodeInputsBox.setInput(ScorePlayerInputType.RUN, 0);
        this.nodeInputsBox.setInput(ScorePlayerInputType.STOP, 1);

        // Create outputs box
        ScorePlayerOutputType.allTypes @=> this.outputTypes;
        new IOBox(1, this.outputTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.setOutput(ScorePlayerOutputType.PLAYER, 0, null);

       // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeInputsModifierBox --> this;
        this.nodeInputsBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();

        // Shreds
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        this.addShreds([processInputsShred]);
    }

    fun void setPart(string nodeID, ezPart part, ezInstrument instrument) {
        // Store a mapping from NodeID --> part and NodeID --> instrument
        part @=> this.partsMap[nodeID];
        instrument @=> this.instrumentMap[nodeID];

        // Add all parts to score
        string keys[0];
        this.partsMap.getKeys(keys);

        ezPart parts[0];
        ezInstrument instruments[0];
        for (string id : keys) {
            this.partsMap[id].print();
            parts << this.partsMap[id];
            instruments << this.instrumentMap[id];
        }

        <<< "Size of parts", parts.size(), "Size of instruments", instruments.size() >>>;

        // Set parts and corresponding instruments
        this.score.parts(parts);
        this.scorePlayer.score(this.score);
        this.scorePlayer.instruments(instruments);
    }

    fun void processInputs() {
        while (this.nodeActive) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                // Check if this input jack has an associated data type
                this.nodeInputsBox.getDataTypeMapping(idx) => int dataType;
                if (dataType == -1) continue;

                // Get UGen connected to this input jack
                this.nodeInputsBox.getJackUGen(idx) @=> UGen ugen;
                if (ugen == null) continue;

                // Input value from ugen
                this.getValueFromUGen(ugen) => float value;

                // Change scenes by input values
                0 => int scoreFinished;
                this.scorePlayer.endPos() - this.scorePlayer.pos() => float beatsRemaining;
                if (beatsRemaining <= 0.) 1 => scoreFinished;
                // <<< "Current Pos", this.scorePlayer.pos(), "End Pos", this.scorePlayer.endPos(), "Score finished?", scoreFinished, "Score playing?", this.scorePlayer.isPlaying(), "Beats remaining", beatsRemaining >>>;
                if (dataType == ScorePlayerInputType.RUN.id) {
                    if (value > 0. && !this.isPlaying && !this.isStopped && !scoreFinished) {
                        <<< "Score Player: Play" >>>;
                        this.scorePlayer.play();
                        1 => this.isPlaying;
                    } else if (value > 0. && !this.isPlaying && !this.isStopped && scoreFinished) {
                        <<< "Score Player: Playing from Beginning" >>>;
                        this.scorePlayer.startPos() => this.scorePlayer.pos;
                        this.scorePlayer.play();
                        1 => this.isPlaying;
                    } else if (value <= 0. && this.isPlaying && this.scorePlayer.isPlaying() && !this.isStopped && !scoreFinished) {
                        <<< "Score Player: Pause" >>>;
                        this.scorePlayer.pause();
                        0 => this.isPlaying;
                    } else if (value <= 0. && this.isPlaying && (this.isStopped || scoreFinished || !this.scorePlayer.isPlaying())) {
                        <<< "Score Player: Reset Play" >>>;
                        0 => this.isPlaying;
                    }
                } else if (dataType == ScorePlayerInputType.STOP.id) {
                    if (value > 0. && !this.isStopped && !scoreFinished) {
                        <<< "Score Player: Stop" >>>;
                        this.scorePlayer.stop();
                        1 => this.isStopped;
                    } else if (value > 0. && !this.isStopped && scoreFinished) {
                        <<< "Score Player: Stopping Finished Score and Resetting Position" >>>;
                        this.scorePlayer.startPos() => this.scorePlayer.pos;
                        1 => this.isStopped;
                    } else if (value <= 0. && this.isStopped) {
                        <<< "Score Player: Reset Stop" >>>;
                        0 => this.isStopped;
                    }
                } else if (dataType == ScorePlayerInputType.RATE.id) {

                } else if (dataType == ScorePlayerInputType.LOOP.id) {
                    if (value > 0. && !this.scorePlayer.loop()) {
                        <<< "Score Player: Enabling Loop" >>>;
                        1 => this.scorePlayer.loop;
                    } else if (value <= 0. && this.scorePlayer.loop()) {
                        <<< "Score Player: Disabling Loop" >>>;
                        0 => this.scorePlayer.loop;
                    }
                }
            }
            10::ms => now;
        }
    }
}
