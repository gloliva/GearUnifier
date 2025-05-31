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
    DropdownMenu @ utilsMenu;

    // Save/Load Handling
    int saveEntryBoxSelected;
    BorderedBox @ saveButton;
    BorderedBox @ loadButton;
    TextEntryBox @ saveFilenameEntryBox;

    vec2 windowSize;

    // Events
    AddNodeEvent @ addNodeEvent;
    MoveCameraEvent @ moveCameraEvent;
    UpdateTextEntryBoxEvent @ updateTextEntryBoxEvent;

    fun @construct(AddNodeEvent addNodeEvent, MoveCameraEvent moveCameraEvent, UpdateTextEntryBoxEvent updateTextEntryBoxEvent) {
        addNodeEvent @=> this.addNodeEvent;
        moveCameraEvent @=> this.moveCameraEvent;
        updateTextEntryBoxEvent @=> this.updateTextEntryBoxEvent;

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
        new DropdownMenu([new Enum(0, "Wavefolder")]) @=> this.effectsMenu;

        // Set name and scale
        this.effectsMenu.setSelectedName("Effects");
        this.effectsMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.effectsMenu.sca;
        1.201 => this.effectsMenu.posZ;
        this.effectsMenu --> GG.scene();
    }

    fun void setUtilsUI() {
        new DropdownMenu([new Enum(0, "Scale")]) @=> this.utilsMenu;

        // Set name and scale
        this.utilsMenu.setSelectedName("Utilities");
        this.utilsMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.utilsMenu.sca;
        1.201 => this.utilsMenu.posZ;
        this.utilsMenu --> GG.scene();
    }

    fun void setSaveUI() {
        // Save and load buttons
        new BorderedBox("Save", 2., 0.5) @=> this.saveButton;
        new BorderedBox("Load", 2., 0.5) @=> this.loadButton;
        @(0.3, 0.3, 1.) => this.saveButton.sca;
        @(0.3, 0.3, 1.) => this.loadButton.sca;
        1.201 => this.saveButton.posZ;
        1.201 => this.loadButton.posZ;
        this.saveButton --> GG.scene();
        this.loadButton --> GG.scene();

        new TextEntryBox(20, 8) @=> this.saveFilenameEntryBox;
        this.saveFilenameEntryBox.setUpdateEvent(this.updateTextEntryBoxEvent);

        @(0.3, 0.3, 1.) => this.saveFilenameEntryBox.sca;
        1.201 => this.saveFilenameEntryBox.posZ;
        this.saveFilenameEntryBox --> GG.scene();
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

            if (this.utilsMenu != null) {
                this.utilsMenu.selectedBox.box.scaWorld().x => float utilsMenuWidth;
                3 * (utilsMenuWidth + menuBuffer) => this.utilsMenu.posX;
                this.topMenuBar.posY() => this.utilsMenu.posY;
            }

            // Reposition bottom bar
            if (this.saveButton != null) {
                -3 => this.saveButton.posX;
                this.bottomMenuBar.posY() => this.saveButton.posY;
            }

            if (this.saveFilenameEntryBox != null) {
                this.bottomMenuBar.posY() => this.saveFilenameEntryBox.posY;
            }

            if (this.loadButton != null) {
                3 => this.loadButton.posX;
                this.bottomMenuBar.posY() => this.loadButton.posY;
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
            translatePos => this.utilsMenu.translate;

            // Move Bottom UI elements
            translatePos => this.saveButton.translate;
            translatePos => this.loadButton.translate;
            translatePos => this.saveFilenameEntryBox.translate;
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
                0 => int uiClickedOn;

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
                    1 => uiClickedOn;
                // Otherwise, check if clicking on the Midi In Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.audioMenu) && !this.audioMenu.expanded) {
                    this.audioMenu.expand();
                    1 => uiClickedOn;
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
                    1 => uiClickedOn;
                // Otherwise, check if clicking on the Midi In Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.midiInMenu) && !this.midiInMenu.expanded) {
                    this.midiInMenu.expand();
                    1 => uiClickedOn;
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
                    1 => uiClickedOn;
                // Otherwise, check if clicking on the MidiOut Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.midiOutMenu) && !this.midiOutMenu.expanded) {
                    this.midiOutMenu.expand();
                    1 => uiClickedOn;
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
                    1 => uiClickedOn;
                // Otherwise, check if clicking on the OSC Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.oscMenu) && !this.oscMenu.expanded) {
                    this.oscMenu.expand();
                    1 => uiClickedOn;
                }

                // If Effects Menu is open, check if clicking on a menu entry
                if (this.effectsMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.effectsMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.effectsMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;

                        // Handle Node type for Effects
                        NodeType.WAVEFOLDER => int nodeType;
                        this.addNodeEvent.set(nodeType, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.effectsMenu.collapse();
                    1 => uiClickedOn;
                // Otherwise, check if clicking on the Effects Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.effectsMenu) && !this.effectsMenu.expanded) {
                    this.effectsMenu.expand();
                    1 => uiClickedOn;
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
                    1 => uiClickedOn;
                // Otherwise, check if clicking on the Sequencer Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.sequencerMenu) && !this.sequencerMenu.expanded) {
                    this.sequencerMenu.expand();
                    1 => uiClickedOn;
                }

                // If Utilities Menu is open, check if clicking on a menu entry
                if (this.utilsMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.utilsMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.utilsMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;
                        NodeType.SCALE => int nodeType;
                        this.addNodeEvent.set(nodeType, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();

                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.utilsMenu.collapse();
                    1 => uiClickedOn;
                // Otherwise, check if clicking on the Utilities Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.utilsMenu) && !this.utilsMenu.expanded) {
                    this.utilsMenu.expand();
                    1 => uiClickedOn;
                }

                // Check if clicking on Save TextEntryBox
                if (this.mouseOverBox(mouseWorldPos, [this.saveFilenameEntryBox, this.saveFilenameEntryBox.box, this.saveFilenameEntryBox.box.box])) {
                    1 => this.saveEntryBoxSelected;
                    1 => uiClickedOn;
                }

                // Check if saving
                if (this.mouseOverBox(mouseWorldPos, [this.saveButton, this.saveButton.box])) {
                    <<< "click on save" >>>;
                    this.saveFilenameEntryBox.signalUpdate(SaveState.SAVE);
                    1 => uiClickedOn;
                // Check if loading
                } else if (this.mouseOverBox(mouseWorldPos, [this.loadButton, this.loadButton.box])) {
                    <<< "click on load" >>>;
                    this.saveFilenameEntryBox.signalUpdate(SaveState.LOAD);
                    1 => uiClickedOn;
                }


                if (!uiClickedOn) 0 => this.saveEntryBoxSelected;
            }

            // Handle adding text to Save TextEntryBox
            if (this.saveEntryBoxSelected) {
                GWindow.keysDown() @=> int keysPressed[];
                for (int key : keysPressed) {

                    // If a number box is selected and a number key is pressed, add the number to the number box
                    if (key >= GWindow.Key_0 && key <= GWindow.Key_9) {
                        this.saveFilenameEntryBox.addChar(key);
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

                        this.saveFilenameEntryBox.addChar(keyStr.charAt(1));
                    } else if (key == GWindow.Key_Backspace) {
                        this.saveFilenameEntryBox.removeChar();
                    } else if (key == GWindow.Key_Enter) {
                        0 => this.saveEntryBoxSelected;
                    }
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

            if (this.utilsMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.utilsMenu) => int dropdownMenuEntryIdx;
                this.utilsMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            GG.nextFrame() => now;
        }
    }
}
