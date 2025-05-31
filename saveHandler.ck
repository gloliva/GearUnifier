@import "HashMap";


public class SaveState {
    0 => static int SAVE;
    1 => static int LOAD;
    2 => static int NEW;
}


public class SaveHandler {
    fun static void save(string filename, HashMap data) {
        FileIO file;

        me.dir() + "saves/" + filename => string filePath;
        <<< "Saving to: ", filePath >>>;
        file.open(filePath, FileIO.WRITE);

        if (!file.good()) {
            <<< "Failed to open file: ", filePath >>>;
            return;
        }

        // Write to primary hashmap
        data.toJson() => string jsonData;

        // Write to file
        file <= jsonData;

        // Close file
        file.close();
    }

    fun static HashMap load(string filename) {
        me.dir() + "saves/" + filename => string filePath;
        <<< "Loading from: ", filePath >>>;

        HashMap.fromJsonFile(filePath) @=> HashMap data;
        return data;
    }
}
