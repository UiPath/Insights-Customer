const fs = require('fs');
const findAllFiles = require('./common');

findAllFiles(processFile);
function processFile(file, pathToFile) {
    let fileContent = fs.readFileSync(pathToFile);
    const backupPath = `${pathToFile.substring(0, pathToFile.length - 3)}_old.js`;

    try {
        fileContent = fs.readFileSync(backupPath);
    } catch (e) {
        console.log(`No backup file was found for ${pathToFile}`);
    }
    // backup
    fs.writeFileSync(pathToFile, fileContent);
    console.log(`File ${pathToFile} was restored from backup`);
}
