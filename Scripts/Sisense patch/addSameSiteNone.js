const fs = require('fs');
const findAllFiles = require('./common');

findAllFiles(processFile);

function processFile(file, pathToFile) {
    const fileContent = fs.readFileSync(pathToFile);
    if (!String(fileContent)
        .startsWith('//modified addSameSiteNone v1')) {
        // backup
        const backupPath = `${pathToFile.substring(0, pathToFile.length - 3)}_old.js`;
        fs.writeFileSync(backupPath, fileContent);
        console.log(`backup file ${backupPath} was created`);
        const newContent = String(fileContent)
            .replace(/(res\.cookie\([\d|\D]+?\);)/g, `$1
            if (Array.isArray(res[Object.getOwnPropertySymbols(res)[0]]['set-cookie'][1])) {
                res[Object.getOwnPropertySymbols(res)[0]]['set-cookie'][1].forEach((cookie, i) => {
                    if (!cookie.endsWith('; SameSite=None')) {
                        res[Object.getOwnPropertySymbols(res)[0]]['set-cookie'][1][i] += '; SameSite=None';
                    }
                });
            } else if (!res[Object.getOwnPropertySymbols(res)[0]]['set-cookie'][1].endsWith('; SameSite=None')) {
                res[Object.getOwnPropertySymbols(res)[0]]['set-cookie'][1] += '; SameSite=None';
            }
     `);
        fs.writeFileSync(pathToFile, `//modified addSameSiteNone v1
` + newContent);
    } else {
        console.log(`File ${file} was already modified before. No changes were made`);
    }
}
