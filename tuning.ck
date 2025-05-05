public class Tuning {
    float octaveVolt;
    int degreeOffset;

    fun @construct() {
        0.1 => this.octaveVolt;
    }

    fun float cv(int degree) {
        return this.cv(degree, 0);
    }

    fun float cv(int degree, int octaveDiff) {
        <<< "ERROR: Override this function based on Child Tuning." >>>;
        return -1;
    }
}


public class DiatonicJI extends Tuning {
    int divisions;
    [
        1.,
        9./8.,
        5./4.,
        4./3.,
        3./2.,
        5./3.,
        15./8.
    ] @=> float stepMultiplier[];

    fun @construct() {
        Tuning();
        this.stepMultiplier.size() => this.divisions;
    }

    fun float cv(int degree, int octaveDiff) {
        (degree / this.divisions)$int + octaveDiff => octaveDiff;
        degree % this.divisions => degree;

        <<< "Scale Degree", this.stepMultiplier[degree] >>>;

        Std.scalef(this.stepMultiplier[degree], 1., 2., 0., this.octaveVolt) => float cvDiff;

        <<< "CV", cvDiff >>>;
        return ( octaveDiff * this.octaveVolt ) + cvDiff;
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
        this.octaveVolt / divisions => cvStep;
    }

    fun float cv(int degree, int octaveDiff) {
        return ( octaveDiff * this.octaveVolt ) + ( (degree + this.degreeOffset) * cvStep );
    }
}
