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
    "#" => static string COMMENT;
    "(" => static string START_ENV;
    ")" => static string END_ENV;
    "o" => static string OCTAVE;
    "a" => static string ATTACK;
    "d" => static string DECAY;
    "r" => static string RELEASE;
    "e" => static string ENVELOPE;
    "\"" => static string REPEAT;
    "::" => static string DURATION;
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
                if (token.substring(0, 1) == ComposeTextToken.COMMENT) {
                    <<< "Skipping comment on line", lineIdx + 1 >>>;
                    break;
                } else if (token == ComposeTextToken.START_SEQ) {
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

                    // Envelope parameters
                    EnvelopePair envPairs[0];
                    EnvelopePair @ currPair;
                    EnvelopePair @ attackPair;
                    EnvelopePair @ decayPair;
                    EnvelopePair @ releasePair;

                    string tokenType;
                    0 => int envelopePairOpen;
                    int numPairs;

                    // Parse optional parameters (e.g. Octave register + Envelope values)
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

                        } else if (
                                token.substring(0, 1).lower() == ComposeTextToken.ENVELOPE ||
                                token.substring(0, 1).lower() == ComposeTextToken.ATTACK ||
                                token.substring(0, 1).lower() == ComposeTextToken.DECAY ||
                                token.substring(0, 1).lower() == ComposeTextToken.RELEASE
                            ) {
                            // Make sure an envelope pair isn't already open
                            if (envelopePairOpen) {
                                "Trying to parse an Envelope pair while one is already open" => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }

                            // Make sure the syntax is correct
                            if (token.length() < 2 || token.substring(1, 1) != ComposeTextToken.START_ENV) {
                                "Trying to parse first value in Envelope pair but missing ( token" => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }

                            // Create a new Envelope Pair and parse env time
                            token.substring(2) => string rampTimeToken;

                            // Check if Smuckish value or duration value
                            if (this.isSmuckishRhythm(rampTimeToken)) {
                                Smuckish.rhythms(rampTimeToken)[0] => float numBeats;
                                new EnvelopePair(numBeats) @=> currPair;

                            } else {
                                this.parseDuration(rampTimeToken, lineIdx) => dur rampTime;
                                new EnvelopePair(rampTime) @=> currPair;
                            }

                            // Open pair
                            token.substring(0, 1).lower() => tokenType;
                            1 => envelopePairOpen;

                        } else {
                            if (!envelopePairOpen) {
                                "Unknown token + not in an Envelope pair" => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }

                            if (token.substring(token.length() - 1, 1) != ComposeTextToken.END_ENV) {
                                "Trying to parse second value in Envelope pair but missing ) token at the end" => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }

                            token.substring(0, token.length() - 1) => string rampValueToken;
                            rampValueToken.toFloat() => float rampValue;

                            // Makre sure conversion was successful
                            if (rampValue == 0. && rampValueToken.charAt(0) != "0".charAt(0)) {
                                "Could not parse Envelope pair 2nd token with value: " + rampValueToken => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }

                            // Complete current pair
                            currPair.set(rampValue);
                            numPairs + 1 => numPairs;

                            // Determine what to set based on token type
                            if (tokenType == ComposeTextToken.ENVELOPE) {
                                envPairs << currPair;
                            } else if (tokenType == ComposeTextToken.ATTACK) {
                                currPair @=> attackPair;
                            } else if (tokenType == ComposeTextToken.DECAY) {
                                currPair @=> decayPair;
                            } else if (tokenType == ComposeTextToken.RELEASE) {
                                currPair @=> releasePair;
                            } else {
                                "Unknown token type" + tokenType + " when closing Envelope pair" => string errorMsg;
                                new ComposeTextError(lineIdx + 1, errorMsg) @=> this.error;
                                return null;
                            }

                            // Close pair
                            0 => envelopePairOpen;
                            "" => tokenType;
                            null @=> currPair;
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

                    // Add additional note data: octave and Envelope values
                    [octave$float, numPairs$float] @=> float data[];

                    if (attackPair != null) {
                        data << attackPair.rhythmType;

                        if (attackPair.rhythmType == RhythmType.SMUCKISH) {
                            data << attackPair.numBeats;
                        } else {
                            data << (attackPair.rampTime / 1::samp);
                        }

                        data << attackPair.rampValue;
                    }

                    if (decayPair != null) {
                        data << decayPair.rhythmType;

                        if (decayPair.rhythmType == RhythmType.SMUCKISH) {
                            data << decayPair.numBeats;
                        } else {
                            data << (decayPair.rampTime / 1::samp);
                        }

                        data << decayPair.rampValue;
                    }

                    if (envPairs.size() > 0) {
                        for (EnvelopePair pair : envPairs) {
                            data << pair.rhythmType;

                            if (pair.rhythmType == RhythmType.SMUCKISH) {
                                data << pair.numBeats;
                            } else {
                                data << (pair.rampTime / 1::samp);
                            }

                            data << pair.rampValue;
                        }
                    }

                    if (releasePair != null) {
                        data << releasePair.rhythmType;

                        if (releasePair.rhythmType == RhythmType.SMUCKISH) {
                            data << releasePair.numBeats;
                        } else {
                            data << (releasePair.rampTime / 1::samp);
                        }

                        data << releasePair.rampValue;
                    }

                    // Set data and add note
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

    fun int isSmuckishRhythm(string token) {
        return token.find(ComposeTextToken.DURATION) == -1;
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
