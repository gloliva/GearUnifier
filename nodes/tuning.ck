@import {"../events.ck", "../utils.ck"}
@import {"../tuning/base.ck", "../tuning/scalaFileParser.ck"}
@import {"../ui/base.ck", "../ui/textBox.ck"}
@import "base.ck"
@import "HashMap"


public class TuningOutputType {
    new Enum(0, "Tuning") @=> static Enum TUNING;

    [
        TuningOutputType.TUNING,
    ] @=> static Enum allTypes[];
}


public class ScaleTuningOptionsBox extends OptionsBox {
    // Text Entry Boxes
    BorderedBox @ filenameBox;

    // Buttons
    Button @ loadButton;
    int buttonClicked;

    // Number Entry Boxes
    NumberEntryBox @ noteOffsetEntryBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Text Entry Boxes
        new BorderedBox("No File Open", 3.5, 0.5) @=> this.filenameBox;

        // Handle Buttons
        new Button("Open", 2., 0.5) @=> this.loadButton;

        // Handle Number Entry Boxes
        new NumberEntryBox(3, 0, NumberBoxType.INT, 2.) @=> this.noteOffsetEntryBox;

        // Set Events
        this.noteOffsetEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0., this.optionNames[0].posY(), 0.201) => this.filenameBox.pos;
        @(0., this.optionNames[1].posY(), 0.201) => this.loadButton.pos;
        @(0.75, this.optionNames[2].posY(), 0.201) => this.noteOffsetEntryBox.pos;

        // Name
        "ScaleSize TextEntryBox" => this.filenameBox.name;
        "LoadFile Button" => this.loadButton.name;
        "NoteOffset NumberEntryBox" => this.noteOffsetEntryBox.name;

        // Connections
        this.filenameBox --> this;
        this.loadButton --> this;
        this.noteOffsetEntryBox --> this;
    }

    fun void setFilename(string filename) {
        this.filenameBox.setName(filename);
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$ScaleTuningNode @=> ScaleTuningNode parentNode;

        // Check if Load button is clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.loadButton, this.loadButton.box])) {
            1 => this.buttonClicked;
            this.loadButton.clickOn();
            return true;
        } else if (parentNode.mouseOverBox(mouseWorldPos, [this, this.noteOffsetEntryBox, this.noteOffsetEntryBox.box, this.noteOffsetEntryBox.box.box])) {
            1 => this.entryBoxSelected;
            this.noteOffsetEntryBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
    }
}


public class ScaleTuningNode extends Node {
    string tuningFilename;
    int degreeOffset;

    // Tuning and Tuning file
    ScaleTuning @ tuning;
    ScalaFileParser scalaFileParser;

    fun @construct() {
        ScaleTuningNode(-24, 4.);
    }

    fun @construct(int degreeOffset) {
        ScaleTuningNode(degreeOffset, 4.);
    }

    fun @construct(int degreeOffset, float xScale) {
        degreeOffset => this.degreeOffset;

        // Set node ID and name
        "Scale Tuning Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Scale Tuning", xScale) @=> this.nodeNameBox;

        // Create outputs box
        new IOBox(1, TuningOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(TuningOutputType.TUNING.id);

        // Create options box
        new ScaleTuningOptionsBox(["", "", "Offset"], xScale) @=> this.nodeOptionsBox;

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeOptionsBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();
    }

    fun int setTuning(string tuningFilename) {
        this.scalaFileParser.open(tuningFilename) => int good;

        if (!good) {
            <<< "ERROR: Couldn't open Scala file with name", tuningFilename >>>;
            return 0;
        }

        tuningFilename => this.tuningFilename;
        this.scalaFileParser.parse() @=> ScalaFile scalaFile;

        if (scalaFile == null) {
            <<< "ERROR: Couldn't parse Scala file with name", tuningFilename >>>;
            return 0;
        }

        scalaFile.printContents();
        if (this.tuning == null) {
            new ScaleTuning(scalaFile.numNotes, scalaFile.centDegrees, scalaFile.period) @=> this.tuning;
            this.degreeOffset => this.tuning.setOffset;
            (this.nodeOptionsBox$ScaleTuningOptionsBox).noteOffsetEntryBox.set(this.degreeOffset);
        } else {
            this.tuning.setScale(scalaFile.numNotes, scalaFile.centDegrees, scalaFile.period);
        }

        this.scalaFileParser.getFilenameFromPath(tuningFilename, 1) => string filename;
        (this.nodeOptionsBox$ScaleTuningOptionsBox).setFilename(filename);

        return 1;
    }

    fun void processOptions() {
        this.nodeOptionsBox$ScaleTuningOptionsBox @=> ScaleTuningOptionsBox optionsBox;

        while (this.nodeActive) {
            if (optionsBox.buttonClicked) {
                GG.openFileDialog(null) => string scalaFilename;

                if (scalaFilename != null) this.setTuning(scalaFilename);
                0 => optionsBox.buttonClicked;
            }

            GG.nextFrame() => now;
        }
    }

    fun void processNumberBoxUpdates() {
        this.nodeOptionsBox$ScaleTuningOptionsBox @=> ScaleTuningOptionsBox optionsBox;

        while (this.nodeActive) {
            optionsBox.updateNumberEntryBoxEvent => now;

            optionsBox.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx ;
            optionsBox.updateNumberEntryBoxEvent.numberBoxValue => int numberBoxValue ;

            if (numberBoxIdx == 0) {
                numberBoxValue => this.degreeOffset;
                <<< "Update degree offset", this.degreeOffset >>>;
                this.degreeOffset => this.tuning.setOffset;
            }
        }
    }

    fun void handleButtonClickEvent() {
        this.nodeOptionsBox$ScaleTuningOptionsBox @=> ScaleTuningOptionsBox optionsBox;

        while (this.nodeActive) {
            optionsBox.loadButton.clickEvent => now;
            spork ~ this.highlightButton(optionsBox.loadButton);

        }
    }

    fun void highlightButton(Button button) {
        while (!GWindow.mouseLeftUp()) {
            GG.nextFrame() => now;
        }

        button.clickOff();
    }

    fun HashMap serialize() {
        HashMap data;
        data.set("nodeClass", Type.of(this).name());
        data.set("nodeID", this.nodeID);
        data.set("tuningFilename", this.tuningFilename);
        data.set("degreeOffset", this.degreeOffset);
        data.set("posX", this.posX());
        data.set("posY", this.posY());
        data.set("posZ", this.posZ());

        return data;
    }
}


public class EDOTuningOptionsBox extends OptionsBox {
    // Number Entry Boxes
    NumberEntryBox @ scaleSizeEntryBox;
    NumberEntryBox @ noteOffsetEntryBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Number Entry Boxes
        new NumberEntryBox(4, 0, NumberBoxType.INT, 2.) @=> this.scaleSizeEntryBox;
        new NumberEntryBox(3, 1, NumberBoxType.INT, 2.) @=> this.noteOffsetEntryBox;

        // Set Events
        this.scaleSizeEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.noteOffsetEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.scaleSizeEntryBox.pos;
        @(0.75, this.optionNames[1].posY(), 0.201) => this.noteOffsetEntryBox.pos;

        // Name
        "ScaleSize NumberEntryBox" => this.scaleSizeEntryBox.name;
        "NoteOffset NumberEntryBox" => this.noteOffsetEntryBox.name;

        // Connections
        this.scaleSizeEntryBox --> this;
        this.noteOffsetEntryBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$EDOTuningNode @=> EDOTuningNode parentNode;

        // Check if Tempo clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.scaleSizeEntryBox, this.scaleSizeEntryBox.box, this.scaleSizeEntryBox.box.box])) {
            1 => this.entryBoxSelected;
            this.scaleSizeEntryBox @=> this.selectedEntryBox;
            return true;
        } else if (parentNode.mouseOverBox(mouseWorldPos, [this, this.noteOffsetEntryBox, this.noteOffsetEntryBox.box, this.noteOffsetEntryBox.box.box])) {
            1 => this.entryBoxSelected;
            this.noteOffsetEntryBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
    }
}


public class EDOTuningNode extends Node {
    int scaleSize;
    int degreeOffset;
    EDO @ tuning;

    fun @construct() {
        EDOTuningNode(12);
    }

    fun @construct(int scaleSize) {
        EDOTuningNode(scaleSize, -24, 4.);
    }

    fun @construct(int scaleSize, int degreeOffset) {
        EDOTuningNode(scaleSize, degreeOffset, 4.);
    }

    fun @construct(int scaleSize, int degreeOffset, float xScale) {
        // Default to 12 TET
        scaleSize => this.scaleSize;
        degreeOffset => this.degreeOffset;
        new EDO(this.scaleSize, this.degreeOffset) @=> this.tuning;

        // Set node ID and name
        "EDO Tuning Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("EDO Tuning", xScale) @=> this.nodeNameBox;

        // Create options box
        new EDOTuningOptionsBox(["Size", "Offset"], xScale) @=> this.nodeOptionsBox;
        (this.nodeOptionsBox$EDOTuningOptionsBox).scaleSizeEntryBox.set(this.scaleSize);
        (this.nodeOptionsBox$EDOTuningOptionsBox).noteOffsetEntryBox.set(this.degreeOffset);

        // Create outputs box
        new IOBox(1, TuningOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(TuningOutputType.TUNING.id);

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeOptionsBox --> this;
        this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();
    }

    fun void processOptions() {
        this.nodeOptionsBox$EDOTuningOptionsBox @=> EDOTuningOptionsBox optionsBox;

        while (this.nodeActive) {
            optionsBox.updateNumberEntryBoxEvent => now;

            optionsBox.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx ;
            optionsBox.updateNumberEntryBoxEvent.numberBoxValue => int numberBoxValue ;

            if (numberBoxIdx == 0) {
                numberBoxValue => this.scaleSize;
                <<< "Update scale size", this.scaleSize >>>;
                this.scaleSize => this.tuning.setDivisions;
            } else if (numberBoxIdx == 1) {
                numberBoxValue => this.degreeOffset;
                <<< "Update degree offset", this.degreeOffset >>>;
                this.degreeOffset => this.tuning.setOffset;
            }

        }
    }

    fun HashMap serialize() {
        HashMap data;
        data.set("nodeClass", Type.of(this).name());
        data.set("nodeID", this.nodeID);
        data.set("scaleSize", this.scaleSize);
        data.set("degreeOffset", this.degreeOffset);
        data.set("posX", this.posX());
        data.set("posY", this.posY());
        data.set("posZ", this.posZ());

        return data;
    }
}
