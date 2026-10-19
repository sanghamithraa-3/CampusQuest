import test from "node:test";
import assert from "node:assert/strict";
import {
  adminCredentialsSchema,
  loginSchema,
  registrationSchema,
} from "../src/utils/validation.js";

test("student registration normalizes email and roll number", () => {
  const result = registrationSchema.parse({
    fullName: "  Ada Lovelace ",
    rollNumber: "  tce123 ",
    department: "Computer Science",
    yearOfStudy: "2",
    email: " ADA@EXAMPLE.EDU ",
    password: "a sufficiently long password",
  });

  assert.equal(result.fullName, "Ada Lovelace");
  assert.equal(result.rollNumber, "TCE123");
  assert.equal(result.yearOfStudy, 2);
  assert.equal(result.email, "ada@example.edu");
});

test("student registration refuses a caller-supplied role", () => {
  const result = registrationSchema.safeParse({
    fullName: "Ada Lovelace",
    rollNumber: "TCE123",
    department: "Computer Science",
    yearOfStudy: 2,
    email: "ada@example.edu",
    password: "a sufficiently long password",
    role: "admin",
  });

  assert.equal(result.success, false);
});

test("login rejects invalid email and empty password", () => {
  assert.equal(
    loginSchema.safeParse({ email: "not-an-email", password: "" }).success,
    false,
  );
});

test("admin credentials require a strong password", () => {
  assert.equal(
    adminCredentialsSchema.safeParse({
      email: "admin@example.edu",
      password: "short",
    }).success,
    false,
  );
});

test("registration rejects passwords longer than bcrypt's byte limit", () => {
  const result = registrationSchema.safeParse({
    fullName: "Ada Lovelace",
    rollNumber: "TCE123",
    department: "Computer Science",
    yearOfStudy: 2,
    email: "ada@example.edu",
    password: "é".repeat(37),
  });

  assert.equal(result.success, false);
});
