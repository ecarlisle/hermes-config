import { test, expect } from '@playwright/test';

test.describe('Smoke — index page', () => {
  test('page compiles and renders', async ({ page }) => {
    const response = await page.goto('/');
    expect(response?.status()).toBe(200);
    await expect(page.locator('body')).toBeVisible();
  });

  test('renders the hero heading', async ({ page }) => {
    await page.goto('/');
    const heading = page.locator('h1');
    await expect(heading).toHaveText('8-Bit Blog');
  });

  test('uses semantic HTML landmarks', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('header')).toHaveCount(1);
    await expect(page.locator('main')).toHaveCount(1);
    await expect(page.locator('footer')).toHaveCount(1);
    await expect(page.locator('nav')).toHaveCount(1);
  });

  test('heading is accessible via aria-labelledby', async ({ page }) => {
    await page.goto('/');
    const section = page.locator('section[aria-labelledby="hero-heading"]');
    await expect(section).toHaveCount(1);
    const heading = page.locator('#hero-heading');
    await expect(heading).toHaveCount(1);
  });

  test('lang attribute is set on html', async ({ page }) => {
    await page.goto('/');
    const lang = await page.locator('html').getAttribute('lang');
    expect(lang).toBe('en');
  });
});
