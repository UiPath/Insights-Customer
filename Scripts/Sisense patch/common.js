const path = require('path');
const fs = require('fs');

const identityFolder = 'identity-service';
const apiGatewayFolder = 'gateway-service';
const myArgs = process.argv.slice(2);
const pathToSisense = myArgs.reduce((p, c) => p + ' ' + c, '').substring(1) || '';

const ssoFiles = [
    'src/middlewares/sso.middleware.js',
    'src/middlewares/openIDAuthentication.middleware.js',
    'src/middlewares/samlAuthentication.middleware.js'
];
const nonSsoFiles = [
    'src/features/authentication/v0.9/authentication.controller.v0.9.js',
    'src/features/authentication/v1/authentication.controller.v1.js',
    'src/features/users/v0.9/users.controller.v0.9.js'
];
let appFolderModificator = '';
try {
    const testPath = path.join(pathToSisense, apiGatewayFolder, ssoFiles[0]);
    fs.readFileSync(testPath);
} catch (e) {
    try {
        const testPath = path.join(pathToSisense, 'app', apiGatewayFolder, ssoFiles[0]);
        fs.readFileSync(testPath);
        appFolderModificator = 'app';
    } catch (e) {
        console.error(
            `Did you specify correct path to Sisense? You should provide it as a command line argument
Neither of files 
    ${path.join(pathToSisense, apiGatewayFolder, ssoFiles[0])}
    ${path.join(pathToSisense, 'app', apiGatewayFolder, ssoFiles[0])}
was not found`
        );
        process.exit(1);
    }
}

module.exports = function (processFile) {
    ssoFiles.forEach((file) => {
        const pathToFile = path.join(pathToSisense, appFolderModificator, apiGatewayFolder, file);
        try {
            processFile(file, pathToFile);
        } catch (e) {
            if(e.toString().includes('openIDAuthentication')){
                // Ignore. This is ok for version < 8.1.1
            } else {
                throw e;
            }
        }
    });
    nonSsoFiles.forEach((file) => {
        const pathToFile = path.join(pathToSisense, appFolderModificator, identityFolder, file);
        processFile(file, pathToFile);
    });

    console.log('Done!');
};
