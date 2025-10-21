public class Tuning {
    float voltPerOctave;
    int degreeOffset;

    fun @construct() {
        Tuning(0.1);
    }

    fun @construct(float voltPerOctave) {
        voltPerOctave => this.voltPerOctave;
    }

    fun void setOffset(int degreeOffset) {
        degreeOffset => this.degreeOffset;

    }

    fun float cv(int degree) {
        return this.cv(degree, 0);
    }

    fun float cv(int degree, int octaveDiff) {
        <<< "ERROR: Override this function based on Child Tuning." >>>;
        return -1;
    }
}


public class ScaleTuning extends Tuning {
    int numNotes;
    float degreesRatio[0];
    float period;

    fun @construct(int numNotes, float degreesRatio[], float period) {
        Tuning();

        numNotes => this.numNotes;
        period => this.period;

        this.degreesRatio << 1.;
        for (float ratio : degreesRatio) {
            if (ratio == period) continue;
            this.degreesRatio << ratio;
        }
    }

    fun int positiveModulo(int dividend, int modulus) {
        return (dividend % modulus + modulus) % modulus;
    }

    fun float cv(int note, int octaveDiff) {
        int numPeriods;
        if (note >= 0) {
            note / this.numNotes => numPeriods;
        } else {
            -((-note - 1) / this.numNotes) - 1;
        }

        this.positiveModulo(note, this.numNotes) => int degree;

        return this.voltPerOctave * (numPeriods * Math.log2(this.period) + Math.log2(this.degreesRatio[degree]));
    }

}


public class EDO extends Tuning {
    int divisions;
    float cvStep;

    fun @construct(int divisions, int degreeOffset) {
        EDO(divisions);
        degreeOffset => this.degreeOffset;
    }

    fun @construct(int divisions) {
        Tuning();
        divisions => this.divisions;
        this.voltPerOctave / divisions => cvStep;
    }

    fun float cv(int degree, int octaveDiff) {
        return ( octaveDiff * this.voltPerOctave ) + ( (degree + this.degreeOffset) * cvStep );
    }
}
