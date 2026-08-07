const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

class MobileReporter {
  static generateReports(testResults) {
    const reportDir = path.join(__dirname, '../reports');
    const excelDir = path.join(__dirname, '../../Test Results/Excel');
    const htmlDir = path.join(__dirname, '../../Test Results/HTML');
    const jsonDir = path.join(__dirname, '../../Test Results/JSON');
    const summaryDir = path.join(__dirname, '../../Test Results/Summary');

    [reportDir, excelDir, htmlDir, jsonDir, summaryDir].forEach(d => {
      if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
    });

    const total = testResults.length;
    const passed = testResults.filter(r => r.status === 'PASSED').length;
    const failed = testResults.filter(r => r.status === 'FAILED').length;
    const skipped = testResults.filter(r => r.status === 'SKIPPED').length;
    const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) : '0.00';

    // 1. JSON Report
    const jsonPath = path.join(jsonDir, 'appium-execution-results.json');
    fs.writeFileSync(jsonPath, JSON.stringify({ total, passed, failed, skipped, passRate, results: testResults }, null, 2));

    // 2. Markdown Summary
    const summaryPath = path.join(summaryDir, 'appium-summary.md');
    const mdContent = `# Android Appium E2E Execution Summary\n\n` +
      `- **Device**: Android Emulator (API 34)\n` +
      `- **Total Test Cases**: ${total}\n` +
      `- **Passed**: ${passed}\n` +
      `- **Failed**: ${failed}\n` +
      `- **Skipped**: ${skipped}\n` +
      `- **Pass Percentage**: ${passRate}%\n\n` +
      `### Test Breakdown\n` +
      testResults.slice(0, 20).map(t => `- [${t.status}] ${t.id}: ${t.name} (${t.duration}ms)`).join('\n');
    fs.writeFileSync(summaryPath, mdContent);

    // 3. HTML Report
    const htmlPath = path.join(htmlDir, 'appium-execution-report.html');
    const htmlContent = `<!DOCTYPE html>
<html>
<head>
  <title>Appium Android E2E Execution Report</title>
  <style>
    body { font-family: Arial, sans-serif; background: #090d16; color: #e2e8f0; padding: 20px; }
    .card { background: #171e2e; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #2d3748; }
    .passed { color: #38bdf8; font-weight: bold; }
    .failed { color: #f43f5e; font-weight: bold; }
  </style>
</head>
<body>
  <h1>Android Appium E2E Automation Report</h1>
  <div class="card">
    <h2>Execution Overview</h2>
    <p>Total: <strong>${total}</strong> | Passed: <span class="passed">${passed}</span> | Failed: <span class="failed">${failed}</span> | Pass Rate: <strong>${passRate}%</strong></p>
  </div>
  <div class="card">
    <h2>Executed Test Cases</h2>
    <table>
      <tr><th>ID</th><th>Module</th><th>Test Name</th><th>Status</th><th>Duration</th></tr>
      ${testResults.map(r => `<tr><td>${r.id}</td><td>${r.module}</td><td>${r.name}</td><td class="${r.status.toLowerCase()}">${r.status}</td><td>${r.duration}ms</td></tr>`).join('')}
    </table>
  </div>
</body>
</html>`;
    fs.writeFileSync(htmlPath, htmlContent);

    // 4. Excel Reports
    const wb = XLSX.utils.book_new();
    const wsAll = XLSX.utils.json_to_sheet(testResults);
    XLSX.utils.book_append_sheet(wb, wsAll, 'Executed Test Cases');
    
    const wsPassed = XLSX.utils.json_to_sheet(testResults.filter(r => r.status === 'PASSED'));
    XLSX.utils.book_append_sheet(wb, wsPassed, 'Passed Tests');

    const wsFailed = XLSX.utils.json_to_sheet(testResults.filter(r => r.status === 'FAILED'));
    XLSX.utils.book_append_sheet(wb, wsFailed, 'Failed Tests');

    XLSX.writeFile(wb, path.join(excelDir, 'Appium_Automation_Test_Report.xlsx'));
    console.log('Successfully generated all Appium reports.');
  }
}

module.exports = MobileReporter;
