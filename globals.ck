@import "HashMap"


public class LiveIO {
    static HashMap ins;
    static HashMap outs;

    fun static void setIn(int shredId, int in, UGen ugen) {
        if (in < 1) {
            <<< "Input Num must greater than 0, received:", in >>>;
            return;
        }

        "Shred-" + shredId => string shredKey;

        // Create inputs map for this shred
        if (!LiveIO.ins.has(shredKey)) {
            HashMap shredMap;
            LiveIO.ins.set(shredKey, shredMap);
        }

        "In-" + in => string inKey;
        LiveIO.ins.get(shredKey) @=> HashMap shredInsMap;
        shredInsMap.set(inKey, ugen);
    }

    fun static HashMap getInsForShred(int shredId) {
        "Shred-" + shredId => string shredKey;
        if (!LiveIO.ins.has(shredKey)) return null;

        return LiveIO.ins.get(shredKey);
    }

    fun static void setOut(int shredId, int out, UGen ugen) {
        if (out < 1) {
            <<< "Output Num must greater than 0, received:", out >>>;
            return;
        }

        "Shred-" + shredId => string shredKey;

        // Create outputs map for this shred
        if (!LiveIO.outs.has(shredKey)) {
            HashMap shredMap;
            LiveIO.outs.set(shredKey, shredMap);
        }

        "Out-" + out => string outKey;
        LiveIO.outs.get(shredKey) @=> HashMap shredOutsMap;
        shredOutsMap.set(outKey, ugen);
    }

    fun static HashMap getOutsForShred(int shredId) {
        "Shred-" + shredId => string shredKey;
        return LiveIO.outs.get(shredKey);
    }
}
