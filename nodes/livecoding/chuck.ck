@import {"../../ui/base.ck", "../../ui/textBox.ck"}
@import "../base.ck"
@import "HashMap"


public class LiveIO {
    static UGen outs[0];
    static UGen ins[0];

    fun static setOut(string path, int out, UGen ugen) {
        path + "-" + out => string key;
        ugen @=> LiveIO.outs[key];
    }
}


public class ChuckScriptOptionsBox extends OptionsBox {
    1 => static int OPEN_BUTTON;
    2 => static int REFRESH_BUTTON;

    // Text boxes
    BorderedBox @ filenameBox;

    // Buttons
    Button @ openButton;
    Button @ refreshButton;
    int buttonClicked;

    fun @construct(float xScale) {
        OptionsBox(["", "", ""], xScale);

        // Create box to display Chuck filename
        new BorderedBox("No File Open", 3.5, 0.5) @=> this.filenameBox;

        // Handle Buttons
        new Button("Open", 2., 0.5) @=> this.openButton;
        new Button("Refresh", 2., 0.5) @=> this.refreshButton;

        // Set position of options
        @(0., this.optionNames[0].posY(), 0.201) => this.filenameBox.pos;
        @(0., this.optionNames[1].posY(), 0.201) => this.openButton.pos;
        @(0., this.optionNames[2].posY(), 0.201) => this.refreshButton.pos;

        // Name
        "Chuck Filename TextEntryBox" => this.filenameBox.name;
        "OpenFile Button" => this.openButton.name;
        "RefreshFile Button" => this.refreshButton.name;

        // Connections
        this.filenameBox --> this;
        this.openButton --> this;
        this.refreshButton --> this;
    }

    fun void setFilename(string filename) {
        this.filenameBox.setName(filename);
    }

    fun void highlightButton(Button button) {
        while (!GWindow.mouseLeftUp()) {
            GG.nextFrame() => now;
        }

        button.clickOff();
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$ChuckScriptNode @=> ChuckScriptNode parentNode;

        // Check if buttons are clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.openButton, this.openButton.box])) {
            this.OPEN_BUTTON => this.buttonClicked;
            this.openButton.clickOn();
            spork ~ highlightButton(this.openButton);
            return true;
        } else if (parentNode.mouseOverBox(mouseWorldPos, [this, this.refreshButton, this.refreshButton.box])) {
            this.REFRESH_BUTTON => this.buttonClicked;
            this.refreshButton.clickOn();
            spork ~ highlightButton(this.refreshButton);
            return true;
        }

        return false;
    }
}


public class ChuckScriptNode extends Node {
    -1 => int scriptShredId;
    string openChuckFilepath;

    fun @construct() {
        ChuckScriptNode(4.);
    }

    fun @construct(float xScale) {
        // Set name and Node ID
        "Chuck-Script-Node" => this.name;
        this.setNodeID();

        // Node name box
        new NameBox("ChuckScript", xScale) @=> this.nodeNameBox;

        // Create options box
        new ChuckScriptOptionsBox(xScale) @=> this.nodeOptionsBox;

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeOptionsBox --> this;
        // this.nodeOutputsModifierBox --> this;
        // this.nodeOutputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();

        // Shreds
        spork ~ this.processOptions() @=> Shred @ processOptionsShred;
        this.addShreds([processOptionsShred]);
    }

    fun void addScript(string scriptPath) {
        // Add a new script
        if (this.scriptShredId == -1) {
            Machine.add(scriptPath) => this.scriptShredId;
            if (this.scriptShredId != 0) {
                this.getFilenameFromPath(scriptPath) => string scriptName;
                (this.nodeOptionsBox$ChuckScriptOptionsBox).setFilename(scriptName);
                me.yield();
                this.setOutputs();
            }
        // Replace the current script
        } else {
            Machine.replace(this.scriptShredId, scriptPath) => this.scriptShredId;
            me.yield();
            this.clearOutputs();
            this.setOutputs();
        }
    }

    fun void setOutputs() {
        string keys[0];
        LiveIO.outs.getKeys(keys);

        // Set up nodeOutputsBox
        Enum ioMenuEntries[0];
        for (int idx; idx < keys.size(); idx++) {
            ioMenuEntries << new Enum(idx, "Out " + (idx + 1));
        }

        new IOBox(keys.size(), ioMenuEntries, IOType.OUTPUT, this.nodeID, this.nodeNameBox.contentBox.scaX()) @=> this.nodeOutputsBox;
        this.nodeOutputsBox --> this;
        this.updatePos();

        StringTokenizer tokenizer;
        tokenizer.delims("-");
        for (string key : keys) {
            <<< "Setting output for key", key >>>;
            LiveIO.outs[key] @=> UGen ugen;
            tokenizer.set(key);
            tokenizer.get(1).toInt() => int outIdx;

            // Set output in nodeOutputsBox
            this.nodeOutputsBox.setOutput(ioMenuEntries[outIdx], outIdx, ugen);
        }
    }

    fun void clearOutputs() {
        this.nodeOutputsBox --< this;
        null @=> this.nodeOutputsBox;
    }

    fun int validateScript(string scriptPath) {
        return false;
    }

    fun string getFilenameFromPath(string filePath) {
        // Tokenize filePath
        StringTokenizer tokenizer(filePath, "/");

        // Return last token
        return tokenizer.get(tokenizer.size() - 1);
    }

    fun void processOptions() {
        this.nodeOptionsBox$ChuckScriptOptionsBox @=> ChuckScriptOptionsBox optionsBox;

        while (this.nodeActive) {
            if (optionsBox.buttonClicked == optionsBox.OPEN_BUTTON) {
                GG.openFileDialog(null) => string chuckFilepath;

                if (chuckFilepath != null) {
                    chuckFilepath => this.openChuckFilepath;
                    this.addScript(chuckFilepath);
                }

                0 => optionsBox.buttonClicked;
            } else if (optionsBox.buttonClicked == optionsBox.REFRESH_BUTTON) {
                if (this.openChuckFilepath != "") {
                    this.addScript(this.openChuckFilepath);
                }

                0 => optionsBox.buttonClicked;
            }

            GG.nextFrame() => now;
        }
    }

    fun void deactivateNode() {
        // Remove chuck script shred
        if (this.scriptShredId != -1) {
            Machine.remove(this.scriptShredId);
        }

        super.deactivateNode();
    }
}
