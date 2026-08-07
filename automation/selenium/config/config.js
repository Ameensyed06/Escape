const path = require('path');

module.exports = {
  baseUrl: process.env.BASE_URL || 'https://ameensyed06.github.io/Escape/',
  headless: process.env.HEADLESS !== 'false',
  implicitWait: 10000,
  explicitWait: 15000,
  browser: 'chrome',
  reportDir: path.join(__dirname, '../reports'),
  screenshotDir: path.join(__dirname, '../screenshots'),
  logDir: path.join(__dirname, '../logs')
};
