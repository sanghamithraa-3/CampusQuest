import { Achievement } from "../models/Achievement.js";
import { User } from "../models/User.js";

export async function getPortfolio(studentId) {
  const student = await User.findOne({
    _id: studentId,
    role: "student",
  }).select("-passwordHash");
  if (!student) {
    return null;
  }

  const achievements = await Achievement.find({ student: student.id }).sort({
    date: -1,
    _id: -1,
  });
  return { student, achievements };
}
