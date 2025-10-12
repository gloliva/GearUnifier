public class ClickableGGen extends GGen {
    fun int mouseOverBox(vec3 mouseWorldPos, GGen boxes[]) {
        this.posX() => float centerX;
        this.posY() => float centerY;
        this.scaX() => float halfW;
        this.scaY() => float halfH;

        for (GGen box : boxes) {
            centerX + (box.posX() * this.scaX()) => centerX;
            centerY + (box.posY() * this.scaY()) => centerY;

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
}
