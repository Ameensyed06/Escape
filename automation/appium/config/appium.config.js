const path = require('path');

module.exports = {
  hostname: process.env.APPIUM_HOST || '127.0.0.1',
  port: parseInt(process.env.APPIUM_PORT || '4723', 10),
  path: '/',
  capabilities: {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2',
    'appium:deviceName': 'Android Emulator',
    'appium:app': path.join(__dirname, '../../build/app/outputs/flutter-apk/app-debug.apk'),
    'appium:appPackage': 'com.example.escape',
    'appium:appActivity': 'com.example.escape.MainActivity',
    'appium:newCommandTimeout': 240,
    'appium:autoGrantPermissions': true
  }
};
