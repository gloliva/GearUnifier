@import "../utils.ck"


public class BorderedBox extends GGen {
    GCube box;
    GText text;

    GCube leftBorder;
    GCube rightBorder;
    GCube topBorder;
    GCube bottomBorder;

    fun @construct() {
        BorderedBox("------");
    }

    fun @construct(string nameText) {
        // Position
        0.101 => this.text.posZ;

        @(-0.975, 0., 0.001) => this.leftBorder.pos;
        @(0.975, 0., 0.001) => this.rightBorder.pos;
        @(0., 0.225, 0.001) => this.topBorder.pos;
        @(0., -0.225, 0.001) => this.bottomBorder.pos;

        // Scale
        @(2., 0.5, 0.2) => this.box.sca;
        @(0.25, 0.25, 0.25) => this.text.sca;

        @(0.05, 0.5, 0.2) => this.leftBorder.sca;
        @(0.05, 0.5, 0.2) => this.rightBorder.sca;
        @(2., 0.05, 0.2) => this.topBorder.sca;
        @(2., 0.05, 0.2) => this.bottomBorder.sca;

        // Text
        nameText => this.text.text;

        // Color
        Color.GRAY => this.box.color;
        @(3., 3., 3., 1.) => this.text.color;

        Color.BLACK => this.leftBorder.color;
        Color.BLACK => this.rightBorder.color;
        Color.BLACK => this.topBorder.color;
        Color.BLACK => this.bottomBorder.color;

        // Names
        "Bordered Box" => this.name;
        "Box" => this.box.name;
        "Name" => this.text.name;

        "Left Border" => this.leftBorder.name;
        "Right Border" => this.rightBorder.name;
        "Top Border" => this.topBorder.name;
        "Bottom Border" => this.bottomBorder.name;

        // Connections
        this.box --> this;
        this.text --> this;

        this.leftBorder --> this;
        this.rightBorder --> this;
        this.topBorder --> this;
        this.bottomBorder --> this;
    }
}


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

    fun @construct(Enum menuItems[]) {
        DropdownMenu(menuItems, "", 0);
    }

    fun @construct(Enum menuItems[], string parentNodeID, int menuNum) {
        menuItems @=> this.menuItems;
        parentNodeID + " Menu" + Std.itoa(menuNum) => this.menuID;

        // Handle menu items
        for (int idx; idx < this.menuItems.size(); idx++) {
            BorderedBox box(this.menuItems[idx].name);

            // Position
            idx * -0.5 => box.posY;
            0.1 => box.posZ;

            // Handle borders
            if (idx == 0 && this.menuItems.size() > 1) {
                box.bottomBorder --< box;
            } else if (idx == this.menuItems.size() - 1) {
                box.topBorder --< box;
            } else {
                box.bottomBorder --< box;
                box.topBorder --< box;
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
        -1 => int menuEntryIdx;

        this.parent()$GGen @=> GGen parent;

        if (!this.expanded) return -1;

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


public class NumberEntryBox {
    fun @construct() {

    }
}
