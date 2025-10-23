public class ScalaFile {
    ".scl" => static string EXTENSION;
    1200. => static float CENTS_PER_OCTAVE;

    string description;
    int numNotes;
    float centDegrees[];
    float period;

    fun @construct(string description, int numNotes, float centDegrees[]) {
        0. => float period;
        if (centDegrees.size() > 0) {
            centDegrees[-1] => period;
        }
        ScalaFile(description, numNotes, centDegrees, period);
    }

    fun @construct(string description, int numNotes, float centDegrees[], float period) {
        description => this.description;
        numNotes => this.numNotes;
        centDegrees @=> this.centDegrees;
        period => this.period;
    }

    fun void printContents() {
        chout <= "Desc: " <= this.description <= IO.nl();
        chout <= "Scale Length: " <= this.numNotes <= IO.nl();
        chout <= "Pitch Values: " <= IO.nl();
        for (float degree : this.centDegrees) {
            chout <= "    " <= degree <= IO.nl();
        }
        chout <= "Period: " <= this.period <= IO.nl();
    }
}


public class ScalaFileParser {
    FileIO scalaFile;

    fun int open(string filename) {
        if (filename.substring(filename.length() - ScalaFile.EXTENSION.length()) != ScalaFile.EXTENSION) {
            cherr <= "ERROR: File with name " <= filename <= " is not a valid Scala file." <= IO.newline();
            return 0;
        }

        this.scalaFile.open(filename, IO.READ);
        // Ensure file opened correctly
        if (!this.scalaFile.good()) {
            cherr <= "ERROR: Unable to open file with name " <= filename <= " for reading." <= IO.newline();
            return 0;
        }

        return 1;
    }

    fun ScalaFile parse() {
        // File tokens
        StringTokenizer tokenizer;
        string line;
        string token;

        // Tuning parameters
        string description;
        int numNotes;
        float centDegrees[0];

        // Parse progress
        0 => int parsedDescriptionText;
        0 => int parsedNumNotes;

        while (this.scalaFile.more()) {
            this.scalaFile.readLine() => line;

            // Skip comments
            if (line.charAt(0) == "!".charAt(0)) continue;

            // Split lines into tokens
            line => tokenizer.set;

            // Parse description text
            if (!parsedDescriptionText) {
                line => description;
                1 => parsedDescriptionText;
            // Parse number of notes
            } else if (!parsedNumNotes && parsedDescriptionText) {
                tokenizer.next() => token;
                token.trim() => token;
                token.toInt() => numNotes;
                1 => parsedNumNotes;
            // Parse pitch values
            } else {
                0 => int containsPeriod;
                0 => int containsSlash;

                tokenizer.next() => token;

                // Determine whether pitch value is a ratio or a cents value
                if (token.find(".") != -1) 1 => containsPeriod;
                if (token.find("/") != -1) 1 => containsSlash;

                // Invalid pitch value
                if (containsPeriod && containsSlash) {
                    cherr <= "ERROR: Invalid pitch value " <= token <= " in Scala file " <= this.scalaFile.filename() <= IO.newline();
                    me.exit();
                // Parse cent values (floats)
                } else if (containsPeriod && !containsSlash) {
                    // Convert to ratio
                    token.toFloat() => float cents;
                    Math.exp2(cents / ScalaFile.CENTS_PER_OCTAVE) => float ratio;
                    centDegrees << ratio;
                // Parse ratios that have slash
                } else if (containsSlash && !containsPeriod) {
                    token.replace("/", " ");
                    token => tokenizer.set;

                    tokenizer.next().toFloat() => float numerator;
                    if (!tokenizer.more()) {
                        cherr <= "ERROR: Pitch value" <= line <= " is not a valid ratio in file " <= this.scalaFile.filename() <= IO.newline();
                        me.exit();
                    }

                    tokenizer.next().toFloat() => float denominator;
                    centDegrees << numerator / denominator;
                // Parse ratios that are single integer (e.g. 3 represents 3/1)
                } else if (!containsSlash && !containsPeriod) {
                    centDegrees << token.toFloat();
                }
            }
        }

        return new ScalaFile(description, numNotes, centDegrees);
    }
}
