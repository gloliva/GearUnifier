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
    TextEntryBox @ filenameEntryBox;

    // Buttons
    Button @ loadButton;
    int buttonClicked;

    // Events
    UpdateTextEntryBoxEvent updateTextEntryBoxEvent;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Text Entry Boxes
        new TextEntryBox("Scala Filename", 20, 3.5) @=> this.filenameEntryBox;

        // Handle Buttons
        new Button("load", 2., 0.5) @=> this.loadButton;

        // Set Events
        this.filenameEntryBox.setUpdateEvent(this.updateTextEntryBoxEvent);

        // Position
        @(0., this.optionNames[0].posY(), 0.201) => this.filenameEntryBox.pos;
        @(0., this.optionNames[1].posY(), 0.201) => this.loadButton.pos;

        // Name
        "ScaleSize TextEntryBox" => this.filenameEntryBox.name;
        "LoadFile Button" => this.loadButton.name;

        // Connections
        this.filenameEntryBox --> this;
        this.loadButton --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$ScaleTuningNode @=> ScaleTuningNode parentNode;

        // Check if Scala Filename is clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.filenameEntryBox, this.filenameEntryBox.box, this.filenameEntryBox.box.box])) {
            <<< "Click on Tuning text box" >>>;
            1 => this.textBoxSelected;
            this.filenameEntryBox @=> this.selectedTextBox;
            return true;
        // Check if Load button is clicked on
        } else if (parentNode.mouseOverBox(mouseWorldPos, [this, this.loadButton, this.loadButton.box])) {
            1 => this.buttonClicked;
            this.loadButton.clickOn();
            return true;
        }

        return false;
    }
}


public class ScaleTuningNode extends Node {
    string tuningFilename;

    // Tuning and Tuning file
    ScaleTuning @ tuning;
    ScalaFileParser scalaFileParser;

    fun @construct() {
        ScaleTuningNode(4.);
    }

    fun @construct(float xScale) {
        // Set node ID and name
        "Scale Tuning Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Scale Tuning", xScale) @=> this.nodeNameBox;

        // Create outputs box
        new IOBox(1, TuningOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(TuningOutputType.TUNING.id);

        // Create options box
        new ScaleTuningOptionsBox(["", ""], xScale) @=> this.nodeOptionsBox;

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
        scalaFile.printContents();
        if (this.tuning == null) {
            new ScaleTuning(scalaFile.numNotes, scalaFile.centDegrees, scalaFile.period) @=> this.tuning;
        } else {
            this.tuning.setScale(scalaFile.numNotes, scalaFile.centDegrees, scalaFile.period);
        }

        return 1;
    }

    fun void processOptions() {
        this.nodeOptionsBox$ScaleTuningOptionsBox @=> ScaleTuningOptionsBox optionsBox;

        while (this.nodeActive) {
            if (optionsBox.textBoxSelected) {
                GWindow.keysDown() @=> int keysPressed[];
                for (int key : keysPressed) {

                    // If a number box is selected and a number key is pressed, add the number to the number box
                    if (key >= GWindow.Key_0 && key <= GWindow.Key_9) {
                        optionsBox.filenameEntryBox.addChar(key);
                    } else if (key >= GWindow.Key_A && key <= GWindow.Key_Z) {
                        // Can't use an empty string or else this doesn't work
                        // So just use any character as a placeholder
                        "z" => string keyStr;
                        keyStr.appendChar(key);

                        // Check if SHIFT held down to make letter Uppercase
                        if (GWindow.key(GWindow.Key_LeftShift) || GWindow.key(GWindow.Key_RightShift)) {
                            keyStr.upper() => keyStr;
                        } else {
                            keyStr.lower() => keyStr;
                        }

                        optionsBox.filenameEntryBox.addChar(keyStr.charAt(1));
                    } else if (key == GWindow.Key_Minus && (GWindow.key(GWindow.Key_LeftShift) || GWindow.key(GWindow.Key_RightShift))) {
                        optionsBox.filenameEntryBox.addChar("_");
                    } else if (key == GWindow.Key_Period || key == GWindow.Key_Minus) {
                        optionsBox.filenameEntryBox.addChar(key);
                    } else if (key == GWindow.Key_Backspace) {
                        optionsBox.filenameEntryBox.removeChar();
                    } else if (key == GWindow.Key_Enter) {
                        0 => optionsBox.textBoxSelected;
                    }
                }
            } else if (optionsBox.buttonClicked) {
                "./scala/" + optionsBox.filenameEntryBox.chars => string scalaFilename;
                this.setTuning(scalaFilename);
                0 => optionsBox.buttonClicked;
            }

            GG.nextFrame() => now;
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
        data.set("posX", this.posX());
        data.set("posY", this.posY());
        data.set("posZ", this.posZ());

        return data;
    }
}


public class EDOTuningOptionsBox extends OptionsBox {
    // Number Entry Boxes
    NumberEntryBox @ scaleSizeEntryBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Number Entry Boxes
        new NumberEntryBox(4, 0, NumberBoxType.INT, 2.) @=> this.scaleSizeEntryBox;

        // Set Events
        this.scaleSizeEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.scaleSizeEntryBox.pos;

        // Name
        "ScaleSize NumberEntryBox" => this.scaleSizeEntryBox.name;

        // Connections
        this.scaleSizeEntryBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$EDOTuningNode @=> EDOTuningNode parentNode;

        // Check if Tempo clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.scaleSizeEntryBox, this.scaleSizeEntryBox.box])) {
            1 => this.entryBoxSelected;
            this.scaleSizeEntryBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
    }
}


public class EDOTuningNode extends Node {
    int scaleSize;
    EDO @ tuning;

    fun @construct() {
        EDOTuningNode(12);
    }

    fun @construct(int scaleSize) {
        EDOTuningNode(scaleSize, 4.);
    }

    fun @construct(int scaleSize, float xScale) {
        // Default to 12 TET
        scaleSize => this.scaleSize;
        new EDO(this.scaleSize, -48) @=> this.tuning;

        // Set node ID and name
        "EDO Tuning Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("EDO Tuning", xScale) @=> this.nodeNameBox;

        // Create options box
        new EDOTuningOptionsBox(["Size"], xScale) @=> this.nodeOptionsBox;
        (this.nodeOptionsBox$EDOTuningOptionsBox).scaleSizeEntryBox.set(this.scaleSize);

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
            }

            this.scaleSize => this.tuning.setDivisions;
        }
    }

    fun HashMap serialize() {
        HashMap data;
        data.set("nodeClass", Type.of(this).name());
        data.set("nodeID", this.nodeID);
        data.set("scaleSize", this.scaleSize);
        data.set("posX", this.posX());
        data.set("posY", this.posY());
        data.set("posZ", this.posZ());

        return data;
    }
}
