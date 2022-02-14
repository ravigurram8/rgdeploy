var mkdirp = require("mkdirp");
var fs = require("fs");
var currentDirectory = __dirname;
var logger = require("../logger/logger")(module);

var configJson;
try {
  configJson = fs.readFileSync(currentDirectory + "/config.json", {
    encoding: "utf8",
  });
} catch (err) {
  logger.error(err);
  configJson = null;
  throw err;
}

if (configJson) {
  var config = JSON.parse(configJson);
}

mkdirp.sync(config.tempDashboardHome);
mkdirp.sync(config.dashboardHome);

module.exports = config;
