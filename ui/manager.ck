// imports
@import "../events.ck"
@import "../utils.ck"
@import "../nodes/base.ck"
@import "menu.ck"


public class UIManager {
    GCube topMenuBar;
    DropdownMenu @ midiInMenu;

    vec2 windowSize;

    // Events
    AddNodeEvent @ addNodeEvent;

    fun @construct(AddNodeEvent addNodeEvent) {
        addNodeEvent @=> this.addNodeEvent;

        // Scale
        0.25 => this.topMenuBar.scaY;
        0.2 => this.topMenuBar.scaZ;

        // Color
        Color.DARKGRAY => this.topMenuBar.color;

        this.topMenuBar --> GG.scene();
    }

    fun void setMidiInUI(Enum midiDeviceNames[]) {
        new DropdownMenu(midiDeviceNames) @=> this.midiInMenu;

        // Set name and scale
        this.midiInMenu.setSelectedName("Midi In");
        this.midiInMenu.setScale(4., 0.5);

        @(0.3, 0.3, 1.) => this.midiInMenu.sca;
        0.201 => this.midiInMenu.posZ;
        this.midiInMenu --> GG.scene();
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

            // Rescale X
            worldBottomRight.x - worldTopLeft.x => this.topMenuBar.scaX;

            // Reposition UI items
            if (this.midiInMenu != null) {

                this.topMenuBar.posY() => this.midiInMenu.posY;
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
                // If MidiIn Menu is open, check if clicking on a menu entry
                if (this.midiInMenu.expanded) {
                    this.mouseOverMenuEntry(mouseWorldPos, this.midiInMenu) => int dropdownMenuEntryIdx;
                    if (dropdownMenuEntryIdx != -1) {
                        this.midiInMenu.getMenuEntry(dropdownMenuEntryIdx) @=> Enum menuEntry;
                        <<< "Selected entry:", menuEntry.id, menuEntry.name >>>;
                        this.addNodeEvent.set(NodeType.MIDI_IN, menuEntry.name, menuEntry.id);
                        this.addNodeEvent.signal();
                    }

                    // Close menu for both 1) clicking on an entry or 2) clicking out of the menu
                    this.midiInMenu.collapse();
                // Otherwise, check if clicking on the Midi In Menu, then open it
                } else if (this.mouseOverDropdownMenu(mouseWorldPos, this.midiInMenu) && !this.midiInMenu.expanded) {
                    this.midiInMenu.expand();
                }
            }

            // Highlight menu items if mouse is over an open menu
            if (this.midiInMenu.expanded) {
                this.mouseOverMenuEntry(mouseWorldPos, this.midiInMenu) => int dropdownMenuEntryIdx;
                this.midiInMenu.highlightHoveredEntry(dropdownMenuEntryIdx);
            }

            GG.nextFrame() => now;
        }
    }
}
