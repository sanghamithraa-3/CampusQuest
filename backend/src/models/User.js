import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    rollNumber: {
      type: String,
      required() {
        return this.role === "student";
      },
      trim: true,
      uppercase: true,
      maxlength: 30,
    },
    department: {
      type: String,
      required() {
        return this.role === "student";
      },
      trim: true,
      maxlength: 100,
    },
    yearOfStudy: {
      type: Number,
      required() {
        return this.role === "student";
      },
      min: 1,
      max: 6,
    },
    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
      unique: true,
      maxlength: 254,
    },
    passwordHash: {
      type: String,
      required: true,
      select: false,
    },
    role: {
      type: String,
      enum: ["student", "admin"],
      default: "student",
      required: true,
    },
    isActive: {
      type: Boolean,
      default: true,
      required: true,
    },
  },
  { timestamps: true },
);

userSchema.index(
  { rollNumber: 1 },
  {
    unique: true,
    partialFilterExpression: { role: "student" },
  },
);

export const User = mongoose.model("User", userSchema);
