const { By, until } = require('selenium-webdriver');

class BasePage {
  constructor(driver) {
    this.driver = driver;
  }

  async open(url) {
    await this.driver.get(url);
  }

  async find(locator) {
    return await this.driver.wait(until.elementLocated(locator), 10000);
  }

  async click(locator) {
    const el = await this.find(locator);
    await el.click();
  }

  async type(locator, text) {
    const el = await this.find(locator);
    await el.clear();
    await el.sendKeys(text);
  }

  async getText(locator) {
    const el = await this.find(locator);
    return await el.getText();
  }

  async isDisplayed(locator) {
    try {
      const el = await this.find(locator);
      return await el.isDisplayed();
    } catch (e) {
      return false;
    }
  }
}

module.exports = BasePage;
