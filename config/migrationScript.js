const logger = require('../logger/logger')(module);

async function execute() {
    try {
        logger.info("Execute any migration changes");
    } catch (error) {
        logger.error('Error in migration ' + error.message);
    }
}

module.exports = {
    execute: execute,
};
