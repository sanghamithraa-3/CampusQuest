import test from "node:test";
import assert from "node:assert/strict";
import { User } from "../src/models/User.js";

test("admin account does not require student identity fields", async () => {
  const admin = new User({
    fullName: "Campus Quest Administrator",
    email: "admin@example.edu",
    passwordHash: "hashed-password",
    role: "admin",
  });

  await assert.doesNotReject(admin.validate());
});

test("student account requires student identity fields", async () => {
  const student = new User({
    fullName: "Student",
    email: "student@example.edu",
    passwordHash: "hashed-password",
    role: "student",
  });

  await assert.rejects(student.validate(), (error) => {
    assert.deepEqual(
      Object.keys(error.errors).sort(),
      ["department", "rollNumber", "yearOfStudy"].sort(),
    );
    return true;
  });
});

test("roll number uniqueness is scoped to student accounts", () => {
  const rollNumberIndex = User.schema.indexes().find(([keys]) =>
    Object.hasOwn(keys, "rollNumber"),
  );

  assert.ok(rollNumberIndex);
  assert.equal(rollNumberIndex[1].unique, true);
  assert.deepEqual(rollNumberIndex[1].partialFilterExpression, {
    role: "student",
  });
});
