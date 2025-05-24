@import "../utils.ck"
@import "base.ck"


public class DropdownMenu extends GGen {
    // Contents
    BorderedBox selectedBox;
    BorderedBox menuItemBoxes[0];

    // Menu Management
    Enum menuItems[];
    int selectedIdx;
    int expanded;

    // Menu Lookup ID
    string menuID;
    int menuIdx;

    fun @construct(Enum menuItems[]) {
        DropdownMenu(menuItems, "", 0);
    }

    fun @construct(Enum menuItems[], int menuIdx) {
        DropdownMenu(menuItems, "", menuIdx);
    }

    fun @construct(Enum menuItems[], string parentNodeID, int menuIdx) {
        menuItems @=> this.menuItems;
        parentNodeID + " Menu" + Std.itoa(menuIdx) => this.menuID;
        menuIdx => this.menuIdx;
        -1 => this.selectedIdx;

        // Handle menu items
        for (int idx; idx < this.menuItems.size(); idx++) {
            BorderedBox box(this.menuItems[idx].name);

            // Position
            idx * -0.5 => box.posY;
            0.2 => box.posZ;

            // Handle borders
            if (this.menuItems.size() > 1) {
                if (idx == 0) {
                    box.bottomBorder --< box;
                } else if (idx == this.menuItems.size() - 1) {
                    box.topBorder --< box;
                } else {
                    box.bottomBorder --< box;
                    box.topBorder --< box;
                }
            }

            // Names
            this.menuItems[idx].name + " Bordered Box" => box.name;

            // Add to lists
            this.menuItemBoxes << box;
        }

        // Names
        "Dropdown Menu" => this.name;
        "Selected Box" => this.selectedBox.name;

        // Connections
        this.selectedBox --> this;
    }

    fun void setSelectedName(string name) {
        this.selectedBox.setName(name);
    }

    fun void setScale(float xScale, float yScale) {
        this.selectedBox.setScale(xScale, yScale);
        for (BorderedBox box : this.menuItemBoxes) {
            box.setScale(xScale, yScale);
        }
    }

    fun Enum getMenuEntry(int idx) {
        if (idx < 0 || idx >= this.menuItems.size()) {
            return null;
        }

        return this.menuItems[idx];
    }

    fun void updateSelectedEntry(int idx) {
        if (idx < 0 || idx > this.menuItems.size()) return;

        idx => this.selectedIdx;
        this.selectedBox.setName(this.menuItems[idx].name);
    }

    fun Enum getSelectedEntry() {
        return this.menuItems[this.selectedIdx];
    }

    fun void expand() {
        if (this.expanded) return;

        for (int idx; idx < this.menuItems.size(); idx++) {
            this.menuItemBoxes[idx] --> this;
        }

        this.selectedBox --< this;
        1 => this.expanded;
    }

    fun void collapse() {
        if (!this.expanded) return;

        for (int idx; idx < this.menuItems.size(); idx++) {
            this.menuItemBoxes[idx] --< this;
        }

        this.selectedBox --> this;
        0 => this.expanded;
    }

    fun int mouseHoverEntry(vec3 mouseWorldPos) {
        if (!this.expanded) return -1;

        -1 => int menuEntryIdx;
        this.parent()$GGen @=> GGen parent;

        for (int idx; idx < this.menuItems.size(); idx++) {
            this.menuItemBoxes[idx] @=> BorderedBox borderedBox;

            parent.posX() + (this.posX() * parent.scaX()) + (borderedBox.posX() * parent.scaX()) + (borderedBox.box.posX() * parent.scaX()) => float centerX;
            parent.posY() + (this.posY() * parent.scaY()) + (borderedBox.posY() * parent.scaY()) + (borderedBox.box.posY() * parent.scaY()) => float centerY;
            (borderedBox.box.scaX() * borderedBox.scaX() * this.scaX() * parent.scaX()) / 2.0 => float halfW;
            (borderedBox.box.scaY() * borderedBox.scaY() * this.scaY() * parent.scaY()) / 2.0 => float halfH;

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

    fun int mouseHoverEntry(vec3 mouseWorldPos, GGen parent, GGen ioBoxParent) {
        if (!this.expanded) return -1;

        -1 => int menuEntryIdx;

        for (int idx; idx < this.menuItems.size(); idx++) {
            this.menuItemBoxes[idx] @=> BorderedBox borderedBox;

            parent.posX() + (ioBoxParent.posX() * parent.scaX()) + (this.posX() * parent.scaX()) + (borderedBox.posX() * parent.scaX()) + (borderedBox.box.posX() * parent.scaX()) => float centerX;
            parent.posY() + (ioBoxParent.posY() * parent.scaY()) + (this.posY() * parent.scaY()) + (borderedBox.posY() * parent.scaY()) + (borderedBox.box.posY() * parent.scaY()) => float centerY;
            (borderedBox.box.scaX() * borderedBox.scaX() * this.scaX() * ioBoxParent.scaX() * parent.scaX()) / 2.0 => float halfW;
            (borderedBox.box.scaY() * borderedBox.scaY() * this.scaY() * ioBoxParent.scaY() * parent.scaY()) / 2.0 => float halfH;

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

    fun void highlightHoveredEntry(int hoveredMenuEntryIdx) {
        if (!this.expanded) return;

        for (int idx; idx < this.menuItems.size(); idx++) {
            this.menuItemBoxes[idx] @=> BorderedBox borderedBox;

            if (idx == hoveredMenuEntryIdx) {
                Color.DARKGRAY => borderedBox.box.color;
            } else {
                Color.GRAY => borderedBox.box.color;
            }
        }
    }
}
