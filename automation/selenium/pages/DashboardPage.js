const { By } = require('selenium-webdriver');
const BasePage = require('./BasePage');

class DashboardPage extends BasePage {
  constructor(driver) {
    super(driver);
    this.focusTimerCard = By.css('.focus-card, #focus-card');
    this.startFocusBtn = By.css('button#start-focus');
    this.streakBadge = By.css('.streak-badge');
  }

  async startFocusSession() {
    if (await this.isDisplayed(this.startFocusBtn)) {
      await this.click(this.startFocusBtn);
    }
  }
}

module.exports = DashboardPage;
