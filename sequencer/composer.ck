@import "base.ck"
@import "smuck"


public class ComposeTextError {
    int lineNumber;
    string errorMsg;

    fun @construct(int lineNumber, string errorMsg) {
        lineNumber => this.lineNumber;
        errorMsg => this.errorMsg;
    }
}


public class ComposeTextToken {
    "<" => static string START_SEQ;
    ">" => static string END_SEQ;
    "!" => static string OPTION;
    "o" => static string OCTAVE;
    "a" => static string ATTACK;
    "d" => static string DECAY;
    "s" => static string SUSTAIN;
    "r" => static string RELEASE;
    "rl" => static string RELEASE_LEVEL;
}


public class ComposeTextOption {
    "loop" => static string LOOP;
    "name" => static string NAME;
}


public class ComposeTextDuration {
    "ms" => static string MILLISECOND;
    "s" => static string SECOND;
    "m" => static string MINUTE;
}


public class ComposeTextDefault {
    4 => static int OCTAVE;
    25::ms => static dur ATTACK;
    0::ms => static dur DECAY;
    0.5 => static float SUSTAIN;
    25::ms => static dur RELEASE;
    0. => static float RELEASE_LEVEL;
}


public class ComposeTextParser {
    string lines[0];
    ComposeTextError warnings[0];
    ComposeTextError @ error;

    fun void setLines(string lines[]) {
        lines @=> this.lines;
    }

    fun int good() {
        if (this.error != null) return false;

        return true;
    }

    fun ezMeasure[] parse() {
        if (lines.size() == 0) {
            <<< "WARNING: No lines to parse" >>>;
            return null;
        }

        // Reset error message on new parse
        null => this.error;

        // Split up each line into tokens
        StringTokenizer tokenizer;
        string token;

        // Measure handling
        ezMeasure measures[0];
        ezMeasure namedMeasures[0];
        ezMeasure @ currMeasure;
        int measureOpen;
        int measureClosed;

        // Option handling
        string measureName;
        1 => int measureLoop;

        // Measure Rhythms
        float noteOnset;

        // Optional information tracking
        -1 => int prevOctave;
        -1. => float prevSustain;
        (-1)::samp => dur prevAttackTime;
        (-1)::samp => dur prevDecayTime;
        (-1)::samp => dur prevReleaseTime;
        -1. => float prevReleaseLevel;

        for (int lineIdx; lineIdx < this.lines.size(); lineIdx++) {
            this.lines[lineIdx] => string currLine;
            currLine => tokenizer.set;

            // Loop through tokens in the line
            while (tokenizer.more()) {
                tokenizer.next() => token;

                // Check if starting a new sequence
                if (token == ComposeTextToken.START_SEQ) {
                    // Check if already in a sequence
                    if (measureOpen) {
                        "Attempting to start a new sequence in the middle of an active sequence." => string errorMsg;
                        new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                        return null;
                    }

                    // Set measure
                    new ezMeasure() @=> currMeasure;
                    1 => measureOpen;
                // Check if ending a sequence
                } else if (token == ComposeTextToken.END_SEQ) {
                    // Check if we are in an open measure
                    if (!measureOpen) {
                        "Attempting to end a sequence before beginning one." => string errorMsg;
                        new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                        return null;
                    }

                    // Check if measure is empty
                    if (currMeasure.beats() == 0) {
                        "Empty measure" => string errorMsg;
                        this.warnings << new ComposeTextError(lineIdx + 1, errorMsg);
                    }

                    // Add measure to measure list and handle looping
                    repeat (measureLoop) {
                        measures << currMeasure;
                    }

                    // Reset curr measure
                    0 => measureOpen;
                    1 => measureLoop;
                    0 => noteOnset;
                    null => currMeasure;

                    // Reset note information tracking
                    -1 => prevOctave;
                    -1. => prevSustain;
                    (-1)::samp => prevAttackTime;
                    (-1)::samp => prevDecayTime;
                    (-1)::samp => prevReleaseTime;
                    -1. => prevReleaseLevel;
                // Check if parsing an option
                } else if (token == ComposeTextToken.OPTION) {
                    // Make sure there is an active measure
                    if (!measureOpen) {
                        "Parsing option information but there is no open measure." => string errorMsg;
                        new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                        return null;
                    }

                    // Check that an option key exists
                    if (!tokenizer.more()) {
                        "No option provided after !" => string errorMsg;
                        new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                        return null;
                    }

                    // Get option key
                    tokenizer.next() => string optionKey;

                    if (optionKey == ComposeTextOption.LOOP) {
                        if (!tokenizer.more()) {
                            "No value provided after the loop option." => string errorMsg;
                            new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                            return null;
                        }

                        // Should be an integer representing number of repeats
                        Std.atoi(tokenizer.next()) => int repeats;

                        if (repeats < 1) {
                            "Loop value must be greater than 1, is set to " + repeats + "." => string errorMsg;
                            new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                            return null;
                        }

                        // Set number of loops
                        repeats => measureLoop;

                        if (tokenizer.more()) {
                            "Extra text after loop option, ignoring remaining characters in this line." => string errorMsg;
                            this.warnings << new ComposeTextError(lineIdx + 1, errorMsg);
                        }
                    } else if (optionKey == ComposeTextOption.NAME) {
                        if (!tokenizer.more()) {
                            "No value provided after the name option." => string errorMsg;
                            new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                            return null;
                        }

                        // Set measure name and save for later recall
                        tokenizer.next() => string name;
                        currMeasure @=> namedMeasures[name];

                        if (tokenizer.more()) {
                            "Extra text after name option, ignoring remaining characters in this line." => string errorMsg;
                            this.warnings << new ComposeTextError(lineIdx + 1, errorMsg);
                        }
                    } else {
                        optionKey => string name;
                        if (!namedMeasures.isInMap(name)) {
                            "No measure with name " + name => string errorMsg;
                            new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                            return null;
                        }

                        // Retrieve named measure and set as current measure
                        namedMeasures[name] @=> currMeasure;
                    }
                // Parse note information
                } else {
                    // Make sure there is an active measure
                    if (!measureOpen) {
                        "Parsing note information but there is no open measure." => string errorMsg;
                        new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                        return null;
                    }

                    // required information
                    -1 => float scaleDegree;
                    string rhythm;
                    float beat;

                    // Optional information
                    -1 => int octave;
                    -1. => float sustain;
                    (-1)::samp => dur attackTime;
                    (-1)::samp => dur decayTime;
                    (-1)::samp => dur releaseTime;
                    -1. => float releaseLevel;

                    ezNote note();

                    // first token is scale degree
                    if (token == "r") {
                        1 => note.isRest;
                    } else {
                        Std.atof(token) => scaleDegree;
                        scaleDegree => note.pitch;
                    }

                    // second token is rhythm
                    if (!tokenizer.more()) {
                        "No rhythm value provided, order should be \"<Scale Degree> <Rhythm> <Optional Parameters>\"" => string errorMsg;
                        new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                        return null;
                    }

                    tokenizer.next() => rhythm;
                    Smuckish.rhythms(rhythm)[0] => beat;
                    beat => note.beats;

                    // Handle onset
                    noteOnset => note.onset;
                    noteOnset + beat => noteOnset;

                    // Parse optional parameters (e.g. ADSR values)
                    while (tokenizer.more()) {
                        tokenizer.next() => token;

                        // Check if Octave parameter
                        if (token.substring(0, 1).lower() == ComposeTextToken.OCTAVE) {
                            token.substring(1) => string octaveToken;
                            octaveToken.toInt() => octave;

                            // Set previous octave
                            octave => prevOctave;

                            // Make sure conversion was successful
                            if (octave == 0 && octaveToken.charAt(0) != "0".charAt(0)) {
                                "Could not parse Octave parameter with value: " + octaveToken => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }

                        } else if (token.substring(0, 1).lower() == ComposeTextToken.ATTACK) {
                            token.substring(1) => string attackToken;
                            this.parseDuration(attackToken, lineIdx) => attackTime;

                            // Set previous attackTime
                            attackTime => prevAttackTime;

                            if ((attackTime / 1::samp) < 0.) {
                                "Could not parse Attack time parameter with value: " + attackToken => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }
                        } else if (token.substring(0, 1).lower() == ComposeTextToken.DECAY) {
                            token.substring(1) => string decayToken;
                            this.parseDuration(decayToken, lineIdx) => decayTime;

                            // Set previous attackTime
                            decayTime => prevDecayTime;

                            if ((decayTime / 1::samp) < 0.) {
                                "Could not parse Decay time parameter with value: " + decayToken => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }
                        } else if (token.substring(0, 1).lower() == ComposeTextToken.SUSTAIN) {
                            token.substring(1) => string sustainToken;
                            sustainToken.toFloat() => sustain;

                            // Set previous sustain
                            sustain => prevSustain;

                            // Make sure conversion was successful
                            if (sustain == 0. && sustainToken.charAt(0) != "0".charAt(0)) {
                                "Could not parse Sustain parameter with value: " + sustainToken => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }

                        } else if (token.substring(0, 1).lower() == ComposeTextToken.RELEASE && token.substring(0, 2).lower() != ComposeTextToken.RELEASE_LEVEL) {
                            token.substring(1) => string releaseToken;
                            this.parseDuration(releaseToken, lineIdx) => releaseTime;

                            // Set previous sustain
                            releaseTime => prevReleaseTime;

                            if ((releaseTime / 1::samp) < 0.) {
                                "Could not parse Release time parameter with value: " + releaseToken => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }
                        // Check if Release Level parameter
                        } else if (token.substring(0, 2).lower() == ComposeTextToken.RELEASE_LEVEL) {
                            token.substring(2) => string releaseLevelToken;
                            releaseLevelToken.toFloat() => releaseLevel;

                            // Set previous sustain
                            releaseLevel => prevReleaseLevel;

                            // Make sure conversion was successful
                            if (releaseLevel == 0. && releaseLevelToken.charAt(0) != "0".charAt(0)) {
                                "Could not parse Release Level parameter with value: " + releaseLevelToken => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }
                        }
                    }

                    // Check if using previous values for optional note information
                    if (octave == -1) {
                        if (prevOctave == -1) {
                            ComposeTextDefault.OCTAVE => octave;
                        } else {
                            prevOctave => octave;
                        }
                    }

                    if (attackTime / 1::samp == -1) {
                        if (prevAttackTime / 1::samp == -1) {
                            ComposeTextDefault.ATTACK => attackTime;
                        } else {
                            prevAttackTime => attackTime;
                        }
                    }

                    if (decayTime / 1::samp == -1) {
                        if (prevDecayTime / 1::samp == -1) {
                            ComposeTextDefault.DECAY => decayTime;
                        } else {
                            prevDecayTime => decayTime;
                        }
                    }

                    if (sustain == -1) {
                        if (prevSustain == -1) {
                            ComposeTextDefault.SUSTAIN => sustain;
                        } else {
                            prevSustain => sustain;
                        }
                    }

                    if (releaseTime / 1::samp == -1) {
                        if (prevReleaseTime / 1::samp == -1) {
                            ComposeTextDefault.RELEASE => releaseTime;
                        } else {
                            prevReleaseTime => releaseTime;
                        }
                    }

                    if (releaseLevel == -1) {
                        if (prevReleaseLevel == -1) {
                            ComposeTextDefault.RELEASE_LEVEL => releaseLevel;
                        } else {
                            prevReleaseLevel => releaseLevel;
                        }
                    }

                    // Velocity data
                    sustain => note.velocity;

                    // Add additional note data, octave, ADR values, and release level
                    [
                        octave$float,
                        attackTime / 1::samp,
                        decayTime / 1::samp,
                        releaseTime / 1::samp,
                        releaseLevel,
                    ] @=> float data[];
                    data => note.data;

                    currMeasure.add(note);
                }
            }
        }

        // Make sure we have closed all measures
        if (measureOpen) {
            "Sequence not closed, maybe missing \">\"" => string errorMsg;
            new ComposeTextError(this.lines.size(), errorMsg) @=> this.error;
            return null;
        }

        // finished parsing, return measures
        return measures;
    }

    fun dur parseDuration(string token, int lineIdx) {
        // determine duration type
        if (token.substring(token.length() >= 2 && token.length() - 2) == ComposeTextDuration.MILLISECOND) {
            token.substring(0, token.length() - 2).toFloat() => float durationValue;
            return durationValue::ms;
        } else if (token.length() >= 1 && token.substring(token.length() - 1) == ComposeTextDuration.SECOND) {
            token.substring(0, token.length() - 1).toFloat() => float durationValue;
            return durationValue::second;
        } else if (token.length() >= 1 && token.substring(token.length() - 1) == ComposeTextDuration.MINUTE) {
            token.substring(0, token.length() - 1).toFloat() => float durationValue;
            return durationValue::minute;
        }

        // If not specified, default to ms
        token.toFloat() => float durationValue;
        if (durationValue == 0 && token.charAt(0) != "0".charAt(0)) {
            return (-1.)::samp;
        }

        return durationValue::ms;
    }
}
