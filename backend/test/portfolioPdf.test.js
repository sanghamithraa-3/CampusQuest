import test from "node:test";
import assert from "node:assert/strict";
import { PassThrough } from "node:stream";
import { streamPortfolioPdf } from "../src/services/portfolioPdf.js";

test("portfolio PDF contains required identity and achievement details", async () => {
  const response = new PassThrough();
  const chunks = [];
  response.on("data", (chunk) => chunks.push(chunk));

  const completed = new Promise((resolve, reject) => {
    response.on("end", resolve);
    response.on("error", reject);
  });

  streamPortfolioPdf(
    {
      student: {
        fullName: "Ada Lovelace",
        rollNumber: "TCE123",
        department: "Computer Science",
        yearOfStudy: 2,
      },
      achievements: [
        {
          title: "First Place",
          category: "Hackathon",
          date: new Date("2026-01-20T00:00:00.000Z"),
          description: "Built an accessibility tool.",
          certificateUrl: "https://example.edu/certificate/1",
        },
      ],
    },
    response,
  );
  await completed;

  const pdf = Buffer.concat(chunks);
  assert.equal(pdf.subarray(0, 5).toString(), "%PDF-");
  assert.ok(pdf.length > 1000);
});
