import test from "node:test";
import assert from "node:assert/strict";
import {
  createAchievementSchema,
  updateAchievementSchema,
} from "../src/utils/achievementValidation.js";

test("achievement accepts an HTTP(S) certificate URL and normalizes fields", () => {
  const result = createAchievementSchema.parse({
    title: "  First Place ",
    category: " Hackathon ",
    date: "2026-01-20",
    description: "  Built an accessibility tool. ",
    certificateUrl: "https://example.edu/certificate/1",
  });

  assert.equal(result.title, "First Place");
  assert.equal(result.category, "Hackathon");
  assert.equal(result.description, "Built an accessibility tool.");
  assert.equal(result.date.toISOString(), "2026-01-20T00:00:00.000Z");
});

test("achievement rejects non-web certificate URLs", () => {
  const result = createAchievementSchema.safeParse({
    title: "First Place",
    category: "Hackathon",
    date: "2026-01-20",
    certificateUrl: "javascript:alert(1)",
  });

  assert.equal(result.success, false);
});

test("achievement updates reject empty bodies and unknown ownership fields", () => {
  assert.equal(updateAchievementSchema.safeParse({}).success, false);
  assert.equal(
    updateAchievementSchema.safeParse({ student: "someone-else" }).success,
    false,
  );
});
