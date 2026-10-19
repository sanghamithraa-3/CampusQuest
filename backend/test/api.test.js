import test from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import app from "../src/app.js";

test("health endpoint remains available without a database session", async () => {
  const response = await request(app).get("/api/health");

  assert.equal(response.status, 200);
  assert.equal(response.body.success, true);
});

test("public registration rejects an admin role", async () => {
  const response = await request(app)
    .post("/api/auth/register")
    .send({
      fullName: "Unauthorized Admin",
      rollNumber: "TCE999",
      department: "Computer Science",
      yearOfStudy: 1,
      email: "admin@example.edu",
      password: "a sufficiently long password",
      role: "admin",
    });

  assert.equal(response.status, 400);
});

test("admin routes require authentication", async () => {
  const response = await request(app).get("/api/admin/students");

  assert.equal(response.status, 401);
});

test("CORS permits only configured local web origins", async () => {
  const allowed = await request(app)
    .get("/api/health")
    .set("Origin", "http://localhost:7357");
  const denied = await request(app)
    .get("/api/health")
    .set("Origin", "https://untrusted.example");

  assert.equal(allowed.headers["access-control-allow-origin"], "http://localhost:7357");
  assert.equal(denied.status, 403);
});
