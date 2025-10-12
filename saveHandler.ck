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
        FileIO saveDir;

        me.dir() + "saves/" => string dirPath;
        dirPath + filename => string filePath;

        // Ensure save directory exists
        saveDir.open(dirPath);

        // Verify directory is valid
        if (!saveDir.isDir()) {
            <<< "Error verifying save directory, path", dirPath, "does not exist.">>>;
            me.exit();
        }

        saveDir.dirList() @=> string files[];
        0 => int fileExists;
        for (string file : files) {
            if (file == filename) {
                1 => fileExists;
                break;
            }
        }

        if (!fileExists) {
            return null;
        }

        <<< "Loading from: ", filePath >>>;

        HashMap.fromJsonFile(filePath) @=> HashMap data;
        return data;
    }
}
