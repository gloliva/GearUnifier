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
}


public class ComposeTextOption {
    "loop" => static string LOOP;
    "name" => static string NAME;
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
                        new ComposeTextError(lineIdx, errorMsg) @=> this.error;
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
                        new ComposeTextError(lineIdx, errorMsg) @=> this.error;
                        return null;
                    }

                    // Check if measure is empty
                    if (currMeasure.beats() == 0) {
                        "Empty measure" => string errorMsg;
                        this.warnings << new ComposeTextError(lineIdx, errorMsg);
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
                // Check if parsing an option
                } else if (token == ComposeTextToken.OPTION) {
                    // Make sure there is an active measure
                    if (!measureOpen) {
                        "Parsing option information but there is no open measure." => string errorMsg;
                        new ComposeTextError(lineIdx, errorMsg) @=> this.error;
                        return null;
                    }

                    // Check that an option key exists
                    if (!tokenizer.more()) {
                        "No option provided after !" => string errorMsg;
                        new ComposeTextError(lineIdx, errorMsg) @=> this.error;
                        return null;
                    }

                    // Get option key
                    tokenizer.next() => string optionKey;

                    if (optionKey == ComposeTextOption.LOOP) {
                        if (!tokenizer.more()) {
                            "No value provided after the loop option." => string errorMsg;
                            new ComposeTextError(lineIdx, errorMsg) @=> this.error;
                            return null;
                        }

                        // Should be an integer representing number of repeats
                        Std.atoi(tokenizer.next()) => int repeats;

                        if (repeats < 1) {
                            "Loop value must be greater than 1, is set to " + repeats + "." => string errorMsg;
                            new ComposeTextError(lineIdx, errorMsg) @=> this.error;
                            return null;
                        }

                        // Set number of loops
                        repeats => measureLoop;

                        if (tokenizer.more()) {
                            "Extra text after loop option, ignoring remaining characters in this line." => string errorMsg;
                            this.warnings << new ComposeTextError(lineIdx, errorMsg);
                        }
                    } else if (optionKey == ComposeTextOption.NAME) {
                        if (!tokenizer.more()) {
                            "No value provided after the name option." => string errorMsg;
                            new ComposeTextError(lineIdx, errorMsg) @=> this.error;
                            return null;
                        }

                        // Set measure name and save for later recall
                        tokenizer.next() => string name;
                        currMeasure @=> namedMeasures[name];

                        if (tokenizer.more()) {
                            "Extra text after name option, ignoring remaining characters in this line." => string errorMsg;
                            this.warnings << new ComposeTextError(lineIdx, errorMsg);
                        }
                    } else {
                        optionKey => string name;
                        if (!namedMeasures.isInMap(name)) {
                            "No measure with name " + name => string errorMsg;
                            new ComposeTextError(lineIdx, errorMsg) @=> this.error;
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
                        new ComposeTextError(lineIdx, errorMsg) @=> this.error;
                        return null;
                    }

                    // required information
                    -1 => float scaleDegree;
                    string rhythm;
                    float beat;
                    dur attackTime;
                    dur releaseTime;

                    ezNote note();

                    // first token is scale degree
                    if (token == "r") {
                        1 => note.isRest;
                    } else {
                        Std.atof(token) => scaleDegree;
                        scaleDegree => note.pitch;
                    }

                    // second token is rhythm
                    tokenizer.next() => rhythm;
                    Smuckish.rhythms(rhythm)[0] => beat;
                    beat => note.beats;

                    // Handle onset
                    noteOnset => note.onset;
                    noteOnset + beat => noteOnset;

                    while (tokenizer.more()) {
                        tokenizer.next() => token;
                    }

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
}
