@import "base.ck"
@import {"../base.ck", "../events.ck"}
@import "../sequencer/composer.ck"
@import "smuck"


public class ComposeBox extends ClickableGGen {
    // Contents
    BorderedBox @ header;
    BorderedBox @ close;
    BorderedBox @ contentBorder;
    BorderedBox @ contentBox;
    BorderedBox @ options;

    // Buttons
    Button @ saveAs;
    Button @ save;
    Button @ open;
    1 => static int SAVE_AS;
    2 => static int SAVE;
    3 => static int OPEN;

    // Compose Text
    string openedFilePath;
    ComposeTextParser parser;

    // Text Handling
    GText lineNumbers[0];
    GText lines[0];
    GCube cursor;
    int topLineIdx;
    23 => int maxLinesOnScreen;

    // Parameters
    string ID;
    string headerName;
    int active;
    int _good;

    // Events
    ComposeBoxUpdateEvent @ updateSceneEvent;

    // smuck measures
    ezMeasure measures[];

    fun @construct(string headerName, ComposeBoxUpdateEvent updateSceneEvent, float xScale, float yScale) {
        headerName => this.headerName;
        updateSceneEvent @=> this.updateSceneEvent;

        // Create content boxes
        new BorderedBox(headerName, Color.BLACK, xScale, 1.) @=> this.header;
        new BorderedBox("x", Color.RED, 0.5, 0.5) @=> this.close;
        new BorderedBox("", xScale, yScale) @=> this.contentBorder;
        new BorderedBox("", Color.LIGHTGRAY, xScale - 1, yScale - 1) @=> this.contentBox;
        new BorderedBox("", Color.BLACK, xScale, 1.) @=> this.options;

        // Create buttons
        new Button("Save As", 2., 0.5) @=> this.saveAs;
        new Button("Save", 2., 0.5) @=> this.save;
        new Button("Open", 2., 0.5) @=> this.open;

        // Position boxes
        (this.header.box.scaY() / 2.) + (this.contentBorder.box.scaY() / 2.) - this.header.bottomBorder.scaY() => float topYPos;
        topYPos => this.header.posY;
        topYPos => this.close.posY;
        -topYPos => this.options.posY;
        (this.header.box.scaX() / 2.) - (this.close.scaX() / 2.) => this.close.posX;

        // Position buttons
        0.1 => float menuBuffer;
        (-menuBuffer - this.saveAs.box.scaX(), -topYPos, 0.) => this.saveAs.pos;
        -topYPos => this.save.posY;
        (menuBuffer + this.saveAs.box.scaX(), -topYPos, 0.) => this.open.pos;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Handle first line and update Text positions
        this.addTextLine("");
        this.updateTextPos();

        // Names
        "Header Box" => this.header.name;
        "Close Box" => this.close.name;
        "Content Border" => this.contentBorder.name;
        "Content Box" => this.contentBox.name;
        "Options Box" => this.options.name;

        "SaveAs Button" => this.saveAs.name;
        "Save Button" => this.save.name;
        "Open Button" => this.open.name;

        // Connections
        this.header --> this;
        this.close --> this;
        this.contentBorder --> this;
        this.contentBox --> this;
        this.options --> this;

        this.saveAs --> this;
        this.save --> this;
        this.open --> this;
    }

    fun void setID(string id) {
        id => this.ID;
    }

    fun int good() {
        return this._good;
    }

    fun void handleButtonPress(int buttonIdx) {
        if (buttonIdx == this.SAVE_AS) {
            <<< "SAVE AS" >>>;
        } else if (buttonIdx == this.SAVE) {
            <<< "SAVE" >>>;
        } else if (buttonIdx == this.OPEN) {
            GG.openFileDialog(null) => string filePath;
            if (filePath != null) {
                this.openComposeTextFile(filePath);
            }
        }
    }

    fun void openComposeTextFile(string filePath) {
        FileIO fio;
        fio.open(filePath, IO.READ);

        if (!fio.good()) {
            cherr <= "ERROR: Unable to open file with name " <= filePath <= " for reading." <= IO.nl();
            return;
        }

        // If no errors, set this as openedFile
        filePath => this.openedFilePath;

        string fileLines[0];

        this.resetTextLines();
        while (fio.more()) {
            fio.readLine() => string line;
            fileLines << line;
            this.addTextLine(line);
        }

        this.updateTextPos();

        // Set lines from file for parsing
        this.parser.setLines(fileLines);

        // Parse the file
        this.parser.parse() @=> ezMeasure measures[];

        if (!this.parser.good()) {
            0 => this._good;
            this.failParseColor();
            <<< "Error on line", this.parser.error.lineNumber >>>;
            <<< "ERROR:", this.parser.error.errorMsg >>>;
            return;
        }

        for (ComposeTextError warning : this.parser.warnings) {
            <<< "Line", warning.lineNumber, "WARNING:", warning.errorMsg >>>;
        }

        1 => this._good;
        this.succeedParseColor();
        <<< "Parsed good! Number of measures", measures.size() >>>;
        for (ezMeasure measure : measures) {
            measure.print();
        }

        // set measures
        measures @=> this.measures;
        this.updateSceneEvent.signal();
    }

    fun void addTextLine(string text) {
        int showLine;
        if (this.lineNumbers.size() - this.topLineIdx < this.maxLinesOnScreen) {
            1 => showLine;
        }

        GText lineNumber;
        Std.itoa(this.lineNumbers.size() + 1) => lineNumber.text;
        0.11 => lineNumber.posZ;
        @(0.45, 0.45, 1.) => lineNumber.sca;
        @(0.1, 0.1, 0.1) => lineNumber.color;
        this.lineNumbers << lineNumber;

        GText line;
        text => line.text;
        0.11 => line.posZ;
        @(0.45, 0.45, 1.) => line.sca;
        Color.BLACK => line.color;
        @(0., 0.5) => line.controlPoints;
        this.lines << line;

        if (showLine) {
            lineNumber --> this;
            line --> this;
        }
    }

    fun void resetTextLines() {
        Math.min(this.lines.size() - this.topLineIdx, this.maxLinesOnScreen) => int numLines;
        for (this.topLineIdx => int currLine; currLine < (this.topLineIdx + numLines); currLine++) {
            this.lineNumbers[currLine] --< this;
            this.lines[currLine] --< this;
        }

        this.lineNumbers.reset();
        this.lines.reset();
    }

    fun void updateTextPos() {
        0.5 => float width;
        Math.min(this.lines.size() - this.topLineIdx, this.maxLinesOnScreen) => int numLines;
        (this.contentBox.box.scaY() / 2.) - width => float startY;
        -(this.contentBox.box.scaX() / 2.) + width => float posX;

        for (this.topLineIdx => int currLine; currLine < (this.topLineIdx + numLines); currLine++) {
            this.lineNumbers[currLine] @=> GText lineNumber;
            this.lines[currLine] @=> GText line;

            posX => lineNumber.posX;
            posX + (width * 2) => line.posX;
            startY - (width * (currLine - this.topLineIdx)) => lineNumber.posY;
            startY - (width * (currLine - this.topLineIdx)) => line.posY;
        }
    }

    fun void failParseColor() {
        this.contentBorder.setColor(Color.RED);
    }

    fun void succeedParseColor() {
        this.contentBorder.setColor(Color.GRAY);
    }

    fun int mouseOverComposeBox(vec3 mouseWorldPos) {
        false => int mouseIsOver;

        this.mouseOverHeader(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverContentBorder(mouseWorldPos) || mouseIsOver => mouseIsOver;
        this.mouseOverOptions(mouseWorldPos) || mouseIsOver => mouseIsOver;

        return mouseIsOver;
    }

    fun int mouseOverHeader(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.header, this.header.box]);
    }

    fun int mouseOverClose(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.close, this.close.box]);
    }

    fun int mouseOverContentBorder(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.contentBorder, this.contentBorder.box]);
    }

    fun int mouseOverContentBox(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.contentBox, this.contentBox.box]);
    }

    fun int mouseOverOptions(vec3 mouseWorldPos) {
        return this.mouseOverBox(mouseWorldPos, [this.options, this.options.box]);
    }

    fun int mouseOverButtons(vec3 mouseWorldPos) {
        if (this.mouseOverBox(mouseWorldPos, [this.saveAs, this.saveAs.box])) return this.SAVE_AS;
        if (this.mouseOverBox(mouseWorldPos, [this.save, this.save.box])) return this.SAVE;
        if (this.mouseOverBox(mouseWorldPos, [this.open, this.open.box])) return this.OPEN;

        return 0;
    }
}
