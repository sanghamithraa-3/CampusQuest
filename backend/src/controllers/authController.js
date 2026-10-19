import bcrypt from "bcryptjs";
import { User } from "../models/User.js";
import { createAccessToken } from "../utils/token.js";

function publicUser(user) {
  return {
    id: user.id,
    fullName: user.fullName,
    rollNumber: user.rollNumber,
    department: user.department,
    yearOfStudy: user.yearOfStudy,
    email: user.email,
    role: user.role,
  };
}

export async function registerStudent(req, res) {
  const { password, ...studentDetails } = req.validatedBody;
  const passwordHash = await bcrypt.hash(password, 12);
  const user = await User.create({
    ...studentDetails,
    passwordHash,
    role: "student",
  });

  return res.status(201).json({
    success: true,
    user: publicUser(user),
    accessToken: createAccessToken(user),
  });
}

export async function login(req, res) {
  const { email, password } = req.validatedBody;
  const user = await User.findOne({ email }).select("+passwordHash");
  const passwordMatches =
    user && (await bcrypt.compare(password, user.passwordHash));

  if (!user || !passwordMatches || !user.isActive) {
    return res.status(401).json({
      success: false,
      message: "Email or password is incorrect",
    });
  }

  return res.json({
    success: true,
    user: publicUser(user),
    accessToken: createAccessToken(user),
  });
}

export async function getCurrentUser(req, res) {
  return res.json({
    success: true,
    user: publicUser(req.user),
  });
}
