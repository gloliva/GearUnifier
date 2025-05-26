// imports
@import "../events.ck"
@import "../utils.ck"
@import "../nodes/base.ck"
@import "menu.ck"


public class UIManager {
    GCube topMenuBar;
    GCube bottomMenuBar;
    DropdownMenu @ audioMenu;
    DropdownMenu @ midiInMenu;
    DropdownMenu @ effectsMenu;
    DropdownMenu @ sequencerMenu;
    DropdownMenu @ utilsMenu;

    vec2 windowSize;

    // Events
    AddNodeEvent @ addNodeEvent;

    fun @construct(AddNodeEvent addNodeEvent) {
        addNodeEvent @=> this.addNodeEvent;

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

    fun void setMidiInUI(Enum midiInDeviceNames[]) {
        new DropdownMenu(midiInDeviceNames) @=> this.midiInMenu;

        // Set name and scale
        this.midiInMenu.setSelectedName("Midi In");
        this.midiInMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.midiInMenu.sca;
        0.201 => this.midiInMenu.posZ;
        this.midiInMenu --> GG.scene();
    }

    fun void setAudioUI() {
        new DropdownMenu([new Enum(0, "Audio In"), new Enum(1, "Audio Out")]) @=> this.audioMenu;

        // Set name and scale
        this.audioMenu.setSelectedName("Audio");
        this.audioMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.audioMenu.sca;
        0.201 => this.audioMenu.posZ;
        this.audioMenu --> GG.scene();
    }

    fun void setEffectsUI() {
        new DropdownMenu([new Enum(0, "Wavefolder")]) @=> this.effectsMenu;

        // Set name and scale
        this.effectsMenu.setSelectedName("Effects");
        this.effectsMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.effectsMenu.sca;
        0.201 => this.effectsMenu.posZ;
        this.effectsMenu --> GG.scene();
    }

    fun void setSequencerUI() {
        new DropdownMenu([new Enum(0, "Sequencer")]) @=> this.sequencerMenu;

        // Set name and scale
        this.sequencerMenu.setSelectedName("Sequencer");
        this.sequencerMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.sequencerMenu.sca;
        0.201 => this.sequencerMenu.posZ;
        this.sequencerMenu --> GG.scene();
    }

    fun void setUtilsUI() {
        new DropdownMenu([new Enum(0, "Scale")]) @=> this.utilsMenu;

        // Set name and scale
        this.utilsMenu.setSelectedName("Utilities");
        this.utilsMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.utilsMenu.sca;
        0.201 => this.utilsMenu.posZ;
        this.utilsMenu --> GG.scene();
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

            // Reposition UI items
            if (this.audioMenu != null) {
                this.audioMenu.selectedBox.box.scaWorld().x => float audioMenuWidth;
                2 * (-audioMenuWidth - menuBuffer) => this.audioMenu.posX;
                this.topMenuBar.posY() => this.audioMenu.posY;
            }

            if (this.midiInMenu != null) {
                this.midiInMenu.selectedBox.box.scaWorld().x => float midiInMenuWidth;
                -midiInMenuWidth - menuBuffer => this.midiInMenu.posX;
                this.topMenuBar.posY() => this.midiInMenu.posY;
            }

            if (this.sequencerMenu != null) {
                // this.sequencerMenu.selectedBox.box.scaWorld().x => float sequencerMenuWidth;
                // 2 * (sequencerMenuWidth + menuBuffer) => this.sequencerMenu.posX;
                this.topMenuBar.posY() => this.sequencerMenu.posY;
            }

            if (this.effectsMenu != null) {
                this.effectsMenu.selectedBox.box.scaWorld().x => float effectsMenuWidth;
                effectsMenuWidth + menuBuffer => this.effectsMenu.posX;
                this.topMenuBar.posY() => this.effectsMenu.posY;
            }

            if (this.utilsMenu != null) {
                this.utilsMenu.selectedBox.box.scaWorld().x => float utilsMenuWidth;
                2 * (utilsMenuWidth + menuBuffer) => this.utilsMenu.posX;
                this.topMenuBar.posY() => this.utilsMenu.posY;
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
                // Otherwise, check if clicking on the Effects Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.effectsMenu) && !this.effectsMenu.expanded) {
                    this.effectsMenu.expand();
                }

                // If Effects Menu is open, check if clicking on a menu entry
                if (this.sequencerMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.sequencerMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.sequencerMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;

                        // Handle Node type for Effects
                        NodeType.SEQUENCER => int nodeType;
                        this.addNodeEvent.set(nodeType, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.sequencerMenu.collapse();
                // Otherwise, check if clicking on the Effects Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.sequencerMenu) && !this.sequencerMenu.expanded) {
                    this.sequencerMenu.expand();
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

            if (this.effectsMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.effectsMenu) => int dropdownMenuEntryIdx;
                this.effectsMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            if (this.sequencerMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.sequencerMenu) => int dropdownMenuEntryIdx;
                this.sequencerMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            GG.nextFrame() => now;
        }
    }
}
