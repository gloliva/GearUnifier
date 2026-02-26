@import {"../../ui/base.ck", "../../ui/textBox.ck"}
@import "../base.ck"
@import "HashMap"


public class LiveIO {
    static HashMap ins;
    static HashMap outs;

    fun static void setNumIns(int shredId, int numIns) {
        "Shred-" + shredId => string shredKey;

        // No negative numbers
        if (numIns < 0) 0 => numIns;

        // Create inputs map for this shred
        HashMap shredMap;
        shredMap.set("NumIns", numIns);
        LiveIO.ins.set(shredKey, shredMap);
    }

    fun static int hasIn(int shredId, int in) {
        // Check if this shred has any inputs
        "Shred-" + shredId => string shredKey;
        if (!LiveIO.ins.has(shredKey)) return false;

        // Check if this shred has inputs at specific input jack
        LiveIO.ins.get(shredKey) @=> HashMap shredInsMap;
        "In-" + in => string inKey;
        if (!shredInsMap.has(inKey)) return false;

        return true;
    }

    fun static UGen getIn(int shredId, int in) {
        if (!LiveIO.hasIn(shredId, in)) return null;

        "Shred-" + shredId => string shredKey;
        LiveIO.ins.get(shredKey) @=> HashMap shredInsMap;
        "In-" + in => string inKey;
        return shredInsMap.getObj(inKey)$UGen;
    }

    fun static HashMap getInsForShred(int shredId) {
        "Shred-" + shredId => string shredKey;
        if (!LiveIO.ins.has(shredKey)) return null;

        return LiveIO.ins.get(shredKey);
    }

    fun static void setOut(int shredId, int out, UGen ugen) {
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

    fun static float getValueFromUGen(UGen ugen) {
        // Value can be from a audio rate UGen (which uses last()),
        // a control rate UGen (which uses next()),
        // or an envelope UGen (which uses value())
        float value;
        if (Type.of(ugen).name() == Step.typeOf().name()) {
            (ugen$Step).next() => value;
        } else if (Type.of(ugen).name() == ADSR.typeOf().name() || Type.of(ugen).name() == Envelope.typeOf().name()) {
            (ugen$Envelope).value() => value;
        } else {
            ugen.last() => value;
        }

        return value;
    }
}


public class ChuckScriptInputType {
    new Enum(0, "Refresh") @=> static Enum REFRESH;

    [
        ChuckScriptInputType.REFRESH,
    ] @=> static Enum allTypes[];
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

        // Create inputs box
        new IOBox(1, ChuckScriptInputType.allTypes, IOType.INPUT, this.nodeID, xScale) @=> this.nodeInputsBox;
        this.nodeInputsBox.setInput(ChuckScriptInputType.REFRESH, 0);

        // Create visibility box
        new VisibilityBox(xScale) @=> this.nodeVisibilityBox;

        // Scale
        @(0.25, 0.25, 1.) => this.sca;

        // Connections
        this.nodeNameBox --> this;
        this.nodeOptionsBox --> this;
        this.nodeInputsBox --> this;
        this.nodeVisibilityBox --> this;

        // Update position
        this.updatePos();

        // Shreds
        spork ~ this.processOptions() @=> Shred @ processOptionsShred;
        spork ~ this.processInputs() @=> Shred @ processInputsShred;
        this.addShreds([processOptionsShred, processInputsShred]);
    }

    fun void addScript(string scriptPath) {
        // Add a new script
        if (this.scriptShredId == -1) {
            Machine.add(scriptPath) => this.scriptShredId;
            if (this.scriptShredId != 0) {
                this.getFilenameFromPath(scriptPath) => string scriptName;
                (this.nodeOptionsBox$ChuckScriptOptionsBox).setFilename(scriptName);
                me.yield();
                this.setInputs();
                this.setOutputs();
            }
        // Replace the current script
        } else {
            Machine.replace(this.scriptShredId, scriptPath) => this.scriptShredId;
            me.yield();
            this.clearInputs();
            this.clearOutputs();
            this.setInputs();
            this.setOutputs();
        }
    }

    fun void setInputs() {
        LiveIO.getInsForShred(this.scriptShredId) @=> HashMap shredInsMap;
        if (shredInsMap == null) return;

        // Get number of inputs
        shredInsMap.getInt("NumIns") => int numIns;

        // Create inputs menu entries
        [ChuckScriptInputType.REFRESH] @=> Enum inputTypes[];
        for (int idx; idx < numIns; idx++) {
            inputTypes << new Enum(idx + 1, "In " + (idx + 1));

            if (this.nodeInputsBox.dataMap.size() <= idx + 1) {
                this.nodeInputsBox.dataMap << -1;
            }
        }
        inputTypes @=> this.inputTypes;

        // Add jacks to inputs IOBox
        for (int idx; idx < numIns; idx++) {
            this.addJack(IOType.INPUT);
            this.nodeInputsBox.setInput(inputTypes[idx + 1], idx + 1);
        }
    }

    fun void setOutputs() {
        // Retrieve UGen mapping that corresponds to the shred
        LiveIO.getOutsForShred(this.scriptShredId) @=> HashMap shredOutsMap;
        shredOutsMap.strKeys() @=> string keys[];

        // Create output types for each output defined in the chuck script
        Enum ioMenuEntries[0];
        for (int idx; idx < keys.size(); idx++) {
            ioMenuEntries << new Enum(idx, "Out " + (idx + 1));
        }

        // Create the outputs box
        new IOBox(keys.size(), ioMenuEntries, IOType.OUTPUT, this.nodeID, this.nodeNameBox.contentBox.scaX()) @=> this.nodeOutputsBox;
        this.nodeOutputsBox --> this;
        this.updatePos();

        // Process the UGens from the script and connect them to this Node's outputs
        StringTokenizer tokenizer;
        tokenizer.delims("-");
        for (string key : keys) {
            shredOutsMap.getObj(key)$UGen @=> UGen ugen;
            tokenizer.set(key);
            tokenizer.get(1).toInt() => int outIdx;

            // Set output in nodeOutputsBox
            this.nodeOutputsBox.setOutput(ioMenuEntries[outIdx], outIdx, ugen);
        }
    }

    fun void clearInputs() {

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

    fun void connect(Node outputNode, UGen ugen, int inputJackIdx) {
        this.nodeInputsBox.getDataTypeMapping(inputJackIdx) => int dataType;
        if (dataType == -1) {
            <<< "No data type mapping for jack", inputJackIdx >>>;
            return;
        }

        // Refresh input jack is handled by processInputs
        // If any other jack is connected to, it's an input to the chuck script
        if (dataType != ChuckScriptInputType.REFRESH.id) {
            LiveIO.getInsForShred(this.scriptShredId) @=> HashMap shredInsMap;
            // (inputJackIdx - 1) because REFRESH is jack 0, and Input 0 is jack 1
            "In-" + (inputJackIdx - 1) => string inKey;
            shredInsMap.set(inKey, ugen);
        }
    }

    fun void disconnect(Node outputNode, UGen ugen, int inputJackIdx) {

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

    fun void processInputs() {
        int refreshed;

        while (this.nodeActive) {
            for (int idx; idx < this.nodeInputsBox.jacks.size(); idx++) {
                // Check if this input jack has an associated data type
                this.nodeInputsBox.getDataTypeMapping(idx) => int dataType;
                if (dataType == -1) continue;

                // Get UGen connected to this input jack
                this.nodeInputsBox.getJackUGen(idx) @=> UGen ugen;
                if (ugen == null) continue;

                // Input value from ugen
                this.getValueFromUGen(ugen) => float value;

                // Handle inputs
                if (dataType == ChuckScriptInputType.REFRESH.id) {
                    if (value > 0. && !refreshed) {
                        // If a script is currently running, refresh the file
                        if (this.openChuckFilepath != "") {
                            this.addScript(this.openChuckFilepath);
                        }
                        1 => refreshed;
                    } else if (value <= 0. && refreshed) {
                        0 => refreshed;
                    }
                }
            }

            // Advance time
            10::ms => now;
        }
    }

    fun void deactivateNode() {
        // Remove chuck script shred
        if (this.scriptShredId != -1) {
            // Remove shred outputs and inputs from LiveIO hashmaps
            "Shred-" + this.scriptShredId => string shredKey;
            if (LiveIO.ins.has(shredKey)) LiveIO.ins.del(shredKey);
            if (LiveIO.outs.has(shredKey)) LiveIO.outs.del(shredKey);

            Machine.remove(this.scriptShredId);
        }

        super.deactivateNode();
    }
}
