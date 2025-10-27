@import "HashMap";


public class SaveState {
    0 => static int SAVE_AS;
    1 => static int SAVE;
    2 => static int LOAD;
    3 => static int NEW;
}


public class SaveHandler {
    ".json" => static string EXTENSION;

    fun static void save(string filePath, HashMap data) {
        FileIO file;

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

    fun static HashMap load(string filePath) {
        <<< "Loading from: ", filePath >>>;
        HashMap.fromJsonFile(filePath) @=> HashMap data;
        return data;
    }
}
