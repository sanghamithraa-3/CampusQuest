import bcrypt from "bcryptjs";
import dotenv from "dotenv";
import { emitKeypressEvents } from "node:readline";
import { connectDB } from "../config/db.js";
import { AdminBootstrap } from "../models/AdminBootstrap.js";
import { User } from "../models/User.js";
import { adminCredentialsSchema } from "../utils/validation.js";

dotenv.config();

function readLine(prompt) {
  return new Promise((resolve, reject) => {
    process.stdout.write(prompt);
    let value = "";
    const onData = (chunk) => {
      const text = chunk.toString();
      const newlineIndex = text.search(/[\r\n]/);
      if (newlineIndex !== -1) {
        value += text.slice(0, newlineIndex);
        process.stdin.off("data", onData);
        process.stdin.pause();
        process.stdout.write("\n");
        resolve(value.trim());
        return;
      }
      value += text;
    };
    process.stdin.on("data", onData);
    process.stdin.once("error", reject);
    process.stdin.resume();
  });
}

function readHidden(prompt) {
  if (!process.stdin.isTTY || typeof process.stdin.setRawMode !== "function") {
    throw new Error("Admin provisioning requires an interactive terminal");
  }

  emitKeypressEvents(process.stdin);
  process.stdin.setRawMode(true);
  process.stdin.resume();
  process.stdout.write(prompt);

  return new Promise((resolve, reject) => {
    let value = "";
    const onKeypress = (character, key = {}) => {
      if (key.ctrl && key.name === "c") {
        process.stdin.off("keypress", onKeypress);
        process.stdin.setRawMode(false);
        process.stdin.pause();
        reject(new Error("Admin provisioning cancelled"));
      } else if (key.name === "return" || key.name === "enter") {
        process.stdin.off("keypress", onKeypress);
        process.stdin.setRawMode(false);
        process.stdin.pause();
        process.stdout.write("\n");
        resolve(value);
      } else if (key.name === "backspace") {
        value = value.slice(0, -1);
      } else if (!key.ctrl && !key.meta && character) {
        value += character;
      }
    };
    process.stdin.on("keypress", onKeypress);
  });
}

async function provisionAdmin() {
  let bootstrapClaimed = false;
  try {
    await connectDB();
    const email = await readLine("Admin email: ");
    const password = await readHidden("Admin password (hidden): ");
    const credentials = adminCredentialsSchema.parse({ email, password });

    await AdminBootstrap.create({ _id: "initial-admin" });
    bootstrapClaimed = true;

    if (await User.exists({ role: "admin" })) {
      throw new Error("An admin account already exists");
    }

    const passwordHash = await bcrypt.hash(credentials.password, 12);
    await User.create({
      fullName: "Campus Quest Administrator",
      email: credentials.email,
      passwordHash,
      role: "admin",
    });

    console.log("Initial admin account provisioned.");
  } catch (error) {
    if (bootstrapClaimed) {
      await AdminBootstrap.deleteOne({ _id: "initial-admin" });
    }
    if (error?.code === 11000) {
      console.error(
        "Admin provisioning is already complete or the email is already in use.",
      );
    } else {
      console.error("Admin provisioning failed:", error.message);
    }
    process.exitCode = 1;
  } finally {
    const mongoose = await import("mongoose");
    await mongoose.default.disconnect();
  }
}

await provisionAdmin();
