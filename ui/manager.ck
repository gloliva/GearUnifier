// imports
@import "../events.ck"
@import "../saveHandler.ck"
@import "../utils.ck"
@import "../nodes/base.ck"
@import "menu.ck"
@import "textBox.ck"


public class UIManager {
    GCube topMenuBar;
    GCube bottomMenuBar;

    // Node Menus
    DropdownMenu @ audioMenu;
    DropdownMenu @ midiInMenu;
    DropdownMenu @ midiOutMenu;
    DropdownMenu @ oscMenu;
    DropdownMenu @ effectsMenu;
    DropdownMenu @ sequencerMenu;
    DropdownMenu @ modifiersMenu;

    // Save/Load Handling
    Button bottomBarButtons[];
    Button @ saveAsButton;
    Button @ saveButton;
    Button @ loadButton;
    Button @ newButton;

    // Window
    vec2 windowSize;

    // Events
    AddNodeEvent @ addNodeEvent;
    MoveCameraEvent @ moveCameraEvent;
    SaveLoadEvent @ saveLoadEvent;

    fun @construct(AddNodeEvent addNodeEvent, MoveCameraEvent moveCameraEvent, SaveLoadEvent saveLoadEvent) {
        addNodeEvent @=> this.addNodeEvent;
        moveCameraEvent @=> this.moveCameraEvent;
        saveLoadEvent @=> this.saveLoadEvent;

        // Pos
        1 => this.topMenuBar.posZ;
        1 => this.bottomMenuBar.posZ;

        // Scale
        0.25 => this.topMenuBar.scaY;
        0.2 => this.topMenuBar.scaZ;

        0.25 => this.bottomMenuBar.scaY;
        0.2 => this.bottomMenuBar.scaZ;

        // Color
        Color.DARKGRAY => this.topMenuBar.color;
        Color.DARKGRAY => this.bottomMenuBar.color;

        this.topMenuBar --> GG.scene();
        this.bottomMenuBar --> GG.scene();
    }

    fun static DropdownMenu createDropdownMenu(string entryNames[]) {
        Enum menu[0];
        for (int idx; idx < entryNames.size(); idx++) {
            menu << new Enum(idx, entryNames[idx]);
        }

        return new DropdownMenu(menu);
    }

    fun void setAudioUI() {
        new DropdownMenu([new Enum(0, "Audio In"), new Enum(1, "Audio Out")]) @=> this.audioMenu;

        // Set name and scale
        this.audioMenu.setSelectedName("Audio");
        this.audioMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.audioMenu.sca;
        1.201 => this.audioMenu.posZ;
        this.audioMenu --> GG.scene();
    }

    fun void setMidiInUI(Enum midiInDeviceNames[]) {
        new DropdownMenu(midiInDeviceNames) @=> this.midiInMenu;

        // Set name and scale
        this.midiInMenu.setSelectedName("Midi In");
        this.midiInMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.midiInMenu.sca;
        1.201 => this.midiInMenu.posZ;
        this.midiInMenu --> GG.scene();
    }

    fun void setMidiOutUI(Enum midiOutDeviceNames[]) {
        new DropdownMenu(midiOutDeviceNames) @=> this.midiOutMenu;

        // Set name and scale
        this.midiOutMenu.setSelectedName("Midi Out");
        this.midiOutMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.midiOutMenu.sca;
        1.201 => this.midiOutMenu.posZ;
        this.midiOutMenu --> GG.scene();
    }

    fun void setOscUI() {
        new DropdownMenu([new Enum(0, "OSC In"), new Enum(1, "OSC Out")]) @=> this.oscMenu;

        // Set name and scale
        this.oscMenu.setSelectedName("OSC");
        this.oscMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.oscMenu.sca;
        1.201 => this.oscMenu.posZ;
        this.oscMenu --> GG.scene();
    }

    fun void setSequencerUI() {
        new DropdownMenu([new Enum(0, "Sequencer"), new Enum(1, "Transport")]) @=> this.sequencerMenu;

        // Set name and scale
        this.sequencerMenu.setSelectedName("Sequencer");
        this.sequencerMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.sequencerMenu.sca;
        1.201 => this.sequencerMenu.posZ;
        this.sequencerMenu --> GG.scene();
    }

    fun void setEffectsUI() {
        new DropdownMenu([new Enum(0, "Wavefolder"), new Enum(1, "Distortion"), new Enum(2, "Delay")]) @=> this.effectsMenu;

        // Set name and scale
        this.effectsMenu.setSelectedName("Effects");
        this.effectsMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.effectsMenu.sca;
        1.201 => this.effectsMenu.posZ;
        this.effectsMenu --> GG.scene();
    }

    fun void setModifiersUI() {
        this.createDropdownMenu(["Scale", "ASR", "ADSR", "Scale Tuning", "EDO Tuning"]) @=> this.modifiersMenu;

        // Set name and scale
        this.modifiersMenu.setSelectedName("Modifiers");
        this.modifiersMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.modifiersMenu.sca;
        1.201 => this.modifiersMenu.posZ;
        this.modifiersMenu --> GG.scene();
    }

    fun void setSaveUI() {
        // Save and load buttons
        new Button("Save As", 2., 0.5) @=> this.saveAsButton;
        new Button("Save", 2., 0.5) @=> this.saveButton;
        new Button("Load", 2., 0.5) @=> this.loadButton;
        new Button("New", 2., 0.5) @=> this.newButton;

        [this.saveAsButton, this.saveButton, this.loadButton, this.newButton] @=> this.bottomBarButtons;
        for (Button button : this.bottomBarButtons) {
            @(0.3, 0.3, 1.) => button.sca;
             1.201 => button.posZ;
             button --> GG.scene();
        }
    }

    fun int mouseOverBox(vec3 mouseWorldPos, GGen boxes[]) {
        if (boxes.size() < 1) return false;

        boxes[0] @=> GGen parentBox;

        parentBox.posX() => float centerX;
        parentBox.posY() => float centerY;
        parentBox.scaX() => float halfW;
        parentBox.scaY() => float halfH;

        for (1 => int idx; idx < boxes.size(); idx++) {
            boxes[idx] @=> GGen box;
            centerX + (box.posX() * parentBox.scaX()) => centerX;
            centerY + (box.posY() * parentBox.scaY()) => centerY;

            halfW * box.scaX() => halfW;
            halfH * box.scaY() => halfH;
        }

        halfW / 2. => halfW;
        halfH / 2. => halfH;

        if (
            mouseWorldPos.x >= centerX - halfW && mouseWorldPos.x <= centerX + halfW
            && mouseWorldPos.y >= centerY - halfH && mouseWorldPos.y <= centerY + halfH
        ) {
            return true;
        }

        return false;
    }

    fun int mouseOverDropdownMenu(vec3 mouseWorldPos, DropdownMenu menu) {
        menu.posX() + (menu.selectedBox.box.posX() * menu.scaX()) => float centerX;
        menu.posY() + (menu.selectedBox.box.posY() * menu.scaY()) => float centerY;
        (menu.selectedBox.box.scaX() * menu.scaX()) / 2.0 => float halfW;
        (menu.selectedBox.box.scaY() * menu.scaY()) / 2.0 => float halfH;

        if (
            mouseWorldPos.x >= centerX - halfW && mouseWorldPos.x <= centerX + halfW
            && mouseWorldPos.y >= centerY - halfH && mouseWorldPos.y <= centerY + halfH
        ) {
            return true;
        }

        return false;
    }

    fun int mouseOverMenuEntry(vec3 mouseWorldPos, DropdownMenu menu) {
        if (!menu.expanded) return -1;

        -1 => int menuEntryIdx;

        for (int idx; idx < menu.menuItems.size(); idx++) {
            menu.menuItemBoxes[idx] @=> BorderedBox borderedBox;

            menu.posX() + (borderedBox.posX() * menu.scaX()) + (borderedBox.box.posX() * menu.scaX()) => float centerX;
            menu.posY() + (borderedBox.posY() * menu.scaY()) + (borderedBox.box.posY() * menu.scaY()) => float centerY;
            (borderedBox.box.scaX() * borderedBox.scaX() * menu.scaX()) / 2.0 => float halfW;
            (borderedBox.box.scaY() * borderedBox.scaY() * menu.scaY()) / 2.0 => float halfH;

            if (
                mouseWorldPos.x >= centerX - halfW && mouseWorldPos.x <= centerX + halfW
                && mouseWorldPos.y >= centerY - halfH && mouseWorldPos.y <= centerY + halfH
            ) {
                idx => menuEntryIdx;
                break;
            }
        }

        return menuEntryIdx;
    }

    fun void resize() {
        while (true) {
            GWindow.resizeEvent() => now;
            GWindow.windowSize() => this.windowSize;

            // Resize menu bars
            GG.camera().screenCoordToWorldPos(@(0, 0), 1) => vec3 worldTopLeft;
            GG.camera().screenCoordToWorldPos(@(this.windowSize.x, this.windowSize.y), 1) => vec3 worldBottomRight;

            // Move Y position
            worldTopLeft.y - (this.topMenuBar.scaY() / 2.0) => this.topMenuBar.posY;
            worldBottomRight.y + (this.bottomMenuBar.scaY() / 2.0) => this.bottomMenuBar.posY;

            // Rescale X
            worldBottomRight.x - worldTopLeft.x => this.topMenuBar.scaX;
            worldBottomRight.x - worldTopLeft.x => this.bottomMenuBar.scaX;

            // Buffer between menus
            0.05 => float menuBuffer;

            // Reposition top bar
            if (this.audioMenu != null) {
                this.audioMenu.selectedBox.box.scaWorld().x => float audioMenuWidth;
                3 * (-audioMenuWidth - menuBuffer) => this.audioMenu.posX;
                this.topMenuBar.posY() => this.audioMenu.posY;
            }

            if (this.midiInMenu != null) {
                this.midiInMenu.selectedBox.box.scaWorld().x => float midiInMenuWidth;
                2 * (-midiInMenuWidth - menuBuffer) => this.midiInMenu.posX;
                this.topMenuBar.posY() => this.midiInMenu.posY;
            }

            if (this.midiOutMenu != null) {
                this.midiOutMenu.selectedBox.box.scaWorld().x => float midiOutMenuWidth;
                -midiOutMenuWidth - menuBuffer => this.midiOutMenu.posX;
                this.topMenuBar.posY() => this.midiOutMenu.posY;
            }

            if (this.oscMenu != null) {
                this.topMenuBar.posY() => this.oscMenu.posY;
            }


            if (this.sequencerMenu != null) {
                this.sequencerMenu.selectedBox.box.scaWorld().x => float sequencerMenuWidth;
                sequencerMenuWidth + menuBuffer => this.sequencerMenu.posX;
                this.topMenuBar.posY() => this.sequencerMenu.posY;
            }

            if (this.effectsMenu != null) {
                this.effectsMenu.selectedBox.box.scaWorld().x => float effectsMenuWidth;
                2 * (effectsMenuWidth + menuBuffer) => this.effectsMenu.posX;
                this.topMenuBar.posY() => this.effectsMenu.posY;
            }

            if (this.modifiersMenu != null) {
                this.modifiersMenu.selectedBox.box.scaWorld().x => float modifiersMenuWidth;
                3 * (modifiersMenuWidth + menuBuffer) => this.modifiersMenu.posX;
                this.topMenuBar.posY() => this.modifiersMenu.posY;
            }

            // Reposition bottom bar buttons
            this.saveAsButton.box.scaWorld().x => float buttonWidth;
            (menuBuffer + buttonWidth) * this.bottomBarButtons.size() - menuBuffer => float totalWidth;
            (-0.5 * totalWidth) + (0.5 * buttonWidth) => float startX;

            for (int idx; idx < this.bottomBarButtons.size(); idx++) {
                this.bottomBarButtons[idx] @=> Button button;
                startX + idx * (buttonWidth + menuBuffer) => button.posX;
                this.bottomMenuBar.posY() => button.posY;
            }
        }
    }

    fun void translate() {
        while (true) {
            this.moveCameraEvent => now;
            @(this.moveCameraEvent.translateX, this.moveCameraEvent.translateY, 0.) => vec3 translatePos;

            // Move UI bars
            translatePos => this.topMenuBar.translate;
            translatePos => this.bottomMenuBar.translate;

            // Move Top UI menus
            translatePos => this.audioMenu.translate;
            translatePos => this.midiInMenu.translate;
            translatePos => this.midiOutMenu.translate;
            translatePos => this.oscMenu.translate;
            translatePos => this.effectsMenu.translate;
            translatePos => this.sequencerMenu.translate;
            translatePos => this.modifiersMenu.translate;

            // Move Bottom UI elements
            for (Button button : this.bottomBarButtons) {
                translatePos => button.translate;
            }
        }
    }

    fun void run() {
        while (true) {
            // Mouse pos in screen coordinates
            GWindow.mousePos() => vec2 mouseCoordPos;

            // Mouse pos in World coordinates
            GG.camera().screenCoordToWorldPos(mouseCoordPos, 1) => vec3 mouseWorldPos;

            // Mouse Click Down on this frame
            if (GWindow.mouseLeftDown() == 1) {

                // If Audio Menu is open, check if clicking on a menu entry
                if (this.audioMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.audioMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.audioMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;

                        // Handle Node type for Audio In and Out
                        NodeType.AUDIO_IN => int nodeType;
                        if (menuEntry.id == 1) NodeType.AUDIO_OUT => nodeType;
                        this.addNodeEvent.set(nodeType, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.audioMenu.collapse();
                // Otherwise, check if clicking on the Midi In Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.audioMenu) && !this.audioMenu.expanded) {
                    this.audioMenu.expand();
                }

                // If MidiIn Menu is open, check if clicking on a menu entry
                if (this.midiInMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.midiInMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.midiInMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;
                        this.addNodeEvent.set(NodeType.MIDI_IN, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.midiInMenu.collapse();
                // Otherwise, check if clicking on the Midi In Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.midiInMenu) && !this.midiInMenu.expanded) {
                    this.midiInMenu.expand();
                }

                // If MidiOut Menu is open, check if clicking on a menu entry
                if (this.midiOutMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.midiOutMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.midiOutMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;
                        this.addNodeEvent.set(NodeType.MIDI_OUT, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.midiOutMenu.collapse();
                // Otherwise, check if clicking on the MidiOut Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.midiOutMenu) && !this.midiOutMenu.expanded) {
                    this.midiOutMenu.expand();
                }

                // If OSC Menu is open, check if clicking on a menu entry
                if (this.oscMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.oscMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.oscMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;
                        NodeType.OSC_IN => int nodeType;
                        if (menuEntry.id == 1) NodeType.OSC_OUT => nodeType;
                        this.addNodeEvent.set(nodeType, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.oscMenu.collapse();
                // Otherwise, check if clicking on the OSC Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.oscMenu) && !this.oscMenu.expanded) {
                    this.oscMenu.expand();
                }

                // If Effects Menu is open, check if clicking on a menu entry
                if (this.effectsMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.effectsMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.effectsMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;

                        // Handle Node type for Effects
                        NodeType.WAVEFOLDER => int nodeType;
                        if (menuEntry.id == 1) NodeType.DISTORTION => nodeType;
                        if (menuEntry.id == 2) NodeType.DELAY => nodeType;
                        this.addNodeEvent.set(nodeType, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.effectsMenu.collapse();
                // Otherwise, check if clicking on the Effects Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.effectsMenu) && !this.effectsMenu.expanded) {
                    this.effectsMenu.expand();
                }

                // If Sequencer Menu is open, check if clicking on a menu entry
                if (this.sequencerMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.sequencerMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.sequencerMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;

                        // Handle Node type for Sequencer
                        NodeType.SEQUENCER => int nodeType;
                        if (menuEntry.id == 1) NodeType.TRANSPORT => nodeType;
                        this.addNodeEvent.set(nodeType, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.sequencerMenu.collapse();
                // Otherwise, check if clicking on the Sequencer Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.sequencerMenu) && !this.sequencerMenu.expanded) {
                    this.sequencerMenu.expand();
                }

                // If Modifiers Menu is open, check if clicking on a menu entry
                if (this.modifiersMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.modifiersMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.modifiersMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;
                        NodeType.SCALE => int nodeType;
                        if (menuEntry.id == 1) NodeType.ASR_ENV => nodeType;
                        if (menuEntry.id == 2) NodeType.ADSR_ENV => nodeType;
                        if (menuEntry.id == 3) NodeType.SCALE_TUNING => nodeType;
                        if (menuEntry.id == 4) NodeType.EDO_TUNING => nodeType;
                        this.addNodeEvent.set(nodeType, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.modifiersMenu.collapse();
                // Otherwise, check if clicking on the Utilities Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.modifiersMenu) && !this.modifiersMenu.expanded) {
                    this.modifiersMenu.expand();
                }

                // Check if saving a new file
                if (this.mouseOverBox(mouseWorldPos, [this.saveAsButton, this.saveAsButton.box])) {
                    this.saveLoadEvent.set(SaveState.SAVE_AS);
                    this.saveLoadEvent.broadcast();
                // Check if saving existing file
                } else if (this.mouseOverBox(mouseWorldPos, [this.saveButton, this.saveButton.box])) {
                    this.saveLoadEvent.set(SaveState.SAVE);
                    this.saveLoadEvent.broadcast();
                // Check if loading
                } else if (this.mouseOverBox(mouseWorldPos, [this.loadButton, this.loadButton.box])) {
                    this.saveLoadEvent.set(SaveState.LOAD);
                    this.saveLoadEvent.broadcast();
                // Check if creating a new patch
                } else if (this.mouseOverBox(mouseWorldPos, [this.newButton, this.newButton.box])) {
                    this.saveLoadEvent.set(SaveState.NEW);
                    this.saveLoadEvent.broadcast();
                }
            }

            // Highlight menu items if mouse is over an open menu
            if (this.audioMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.audioMenu) => int dropdownMenuEntryIdx;
                this.audioMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            if (this.midiInMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.midiInMenu) => int dropdownMenuEntryIdx;
                this.midiInMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            if (this.midiOutMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.midiOutMenu) => int dropdownMenuEntryIdx;
                this.midiOutMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            if (this.oscMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.oscMenu) => int dropdownMenuEntryIdx;
                this.oscMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            if (this.sequencerMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.sequencerMenu) => int dropdownMenuEntryIdx;
                this.sequencerMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            if (this.effectsMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.effectsMenu) => int dropdownMenuEntryIdx;
                this.effectsMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            if (this.modifiersMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.modifiersMenu) => int dropdownMenuEntryIdx;
                this.modifiersMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            GG.nextFrame() => now;
        }
    }
}
