// Renders the gig covers (HTML) to PNG at 1280 x 769: node render.js <in.html> <out.png> ...
const { chromium } = require('playwright');
(async () => {
	const browser = await chromium.launch();
	const page = await browser.newPage({ viewport: { width: 1280, height: 769 } });
	const args = process.argv.slice(2);
	for (let i = 0; i < args.length; i += 2) {
		await page.goto('file://' + args[i]);
		await page.waitForTimeout(300);
		await page.screenshot({ path: args[i + 1] });
		console.log('wrote', args[i + 1]);
	}
	await browser.close();
})();
