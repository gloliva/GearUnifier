@import "../../events.ck"
@import "../../utils.ck"
@import "../../ui/textBox.ck"
@import "../base.ck"
@import "HashMap"


public class TransportOutputType {
    new Enum(0, "Beat") @=> static Enum BEAT;

    [
        TransportOutputType.BEAT,
    ] @=> static Enum allTypes[];
}


public class TransportOptionsBox extends OptionsBox {
    // Number Entry Boxes
    NumberEntryBox @ tempoEntryBox;
    NumberEntryBox @ beatDivEntryBox;

    // Events
    UpdateNumberEntryBoxEvent updateNumberEntryBoxEvent;

    fun @construct(string optionNames[], float xScale) {
        OptionsBox(optionNames, xScale);

        // Handle Number Entry Boxes
        new NumberEntryBox(3, 0, NumberBoxType.INT, 2.) @=> this.tempoEntryBox;
        new NumberEntryBox(6, 1, NumberBoxType.FLOAT, 2.) @=> this.beatDivEntryBox;

        // Set Events
        this.tempoEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);
        this.beatDivEntryBox.setUpdateEvent(this.updateNumberEntryBoxEvent);

        // Position
        @(0.75, this.optionNames[0].posY(), 0.201) => this.tempoEntryBox.pos;
        @(0.75, this.optionNames[1].posY(), 0.201) => this.beatDivEntryBox.pos;

        // Name
        "Tempo NumberEntryBox" => this.tempoEntryBox.name;
        "Beat Divider NumberEntryBox" => this.beatDivEntryBox.name;

        // Connections
        this.tempoEntryBox --> this;
        this.beatDivEntryBox --> this;
    }

    fun void handleMouseOver(vec3 mouseWorldPos) {
        // Nothing to do here
        return;
    }

    fun int handleMouseLeftDown(vec3 mouseWorldPos) {
        this.parent()$TransportNode @=> TransportNode parentNode;

        // Check if Tempo clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.tempoEntryBox, this.tempoEntryBox.box])) {
            1 => entryBoxSelected;
            this.tempoEntryBox @=> this.selectedEntryBox;
            return true;
        }

        // Check if Beat Divider clicked on
        if (parentNode.mouseOverBox(mouseWorldPos, [this, this.beatDivEntryBox, this.beatDivEntryBox.box])) {
            1 => entryBoxSelected;
            this.beatDivEntryBox @=> this.selectedEntryBox;
            return true;
        }

        return false;
    }
}


public class TransportNode extends Node {
    float tempo;
    float beatDiv;


    fun @construct() {
        TransportNode(120., 1., 4.);
    }

    fun @construct(float xScale) {
        TransportNode(120., 1., xScale);
    }

    fun @construct(float tempo, float beatDiv, float xScale) {
        // Initialize tempo variables
        tempo => this.tempo;
        beatDiv => this.beatDiv;

        // Set node ID and name
        "Transport Node" => this.name;
        this.name() + " ID " + Std.itoa(Math.random()) => this.nodeID;

        // Node name box
        new NameBox("Transport", xScale) @=> this.nodeNameBox;

        // Create options box
        new TransportOptionsBox(["Tempo", "Beat Mult"], xScale) @=> this.nodeOptionsBox;
        (this.nodeOptionsBox$TransportOptionsBox).tempoEntryBox.set(Std.ftoi(tempo));
        (this.nodeOptionsBox$TransportOptionsBox).beatDivEntryBox.set(beatDiv);

        // Create outputs box
        new IOBox(1, TransportOutputType.allTypes, IOType.OUTPUT, this.nodeID, xScale) @=> this.nodeOutputsBox;
        this.nodeOutputsBox.menus[0].updateSelectedEntry(TransportOutputType.BEAT.id);

        // Set Step Ugen to jack output for sending Beat information
        this.nodeOutputsBox.jacks[0].setUgen(this.nodeOutputsBox.outs[0]);
        this.getBeat() => this.nodeOutputsBox.outs[TransportOutputType.BEAT.id].next;

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

        // Shreds
        spork ~ this.processOptions() @=> Shred @ processOptionsShred;
        this.addShreds([processOptionsShred]);
    }

    fun float getBeat() {
        return ((60. / this.tempo) / this.beatDiv);
    }

    fun void processOptions() {
        this.nodeOptionsBox$TransportOptionsBox @=> TransportOptionsBox optionsBox;

        while (this.nodeActive) {
            optionsBox.updateNumberEntryBoxEvent => now;

            optionsBox.updateNumberEntryBoxEvent.numberBoxIdx => int numberBoxIdx ;
            optionsBox.updateNumberEntryBoxEvent.numberBoxFloatValue => float numberBoxFloatValue ;

            if (numberBoxIdx == 0) {
                numberBoxFloatValue => this.tempo;
            } else if (numberBoxIdx == 1) {
                numberBoxFloatValue => this.beatDiv;
            }

            this.getBeat() => this.nodeOutputsBox.outs[TransportOutputType.BEAT.id].next;
        }
    }

    fun HashMap serialize() {
        HashMap data;
        this.serialize(data);

        data.set("tempo", this.tempo);
        data.set("beatDiv", this.beatDiv);

        return data;
    }
}
