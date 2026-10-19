import { Achievement } from "../models/Achievement.js";
import { User } from "../models/User.js";

function parsePagination(query) {
  const page = Math.max(1, Number.parseInt(query.page ?? "1", 10) || 1);
  const limit = Math.min(
    100,
    Math.max(1, Number.parseInt(query.limit ?? "25", 10) || 25),
  );
  return { page, limit, skip: (page - 1) * limit };
}

export async function listStudents(req, res) {
  const { page, limit, skip } = parsePagination(req.query);
  const [students, total] = await Promise.all([
    User.find({ role: "student" })
      .select("-passwordHash")
      .sort({ fullName: 1, _id: 1 })
      .skip(skip)
      .limit(limit),
    User.countDocuments({ role: "student" }),
  ]);
  return res.json({
    success: true,
    students,
    pagination: { page, limit, total },
  });
}

export async function setStudentActiveState(req, res) {
  const { isActive } = req.validatedBody;
  const student = await User.findOneAndUpdate(
    { _id: req.params.studentId, role: "student" },
    { $set: { isActive } },
    { new: true, runValidators: true },
  ).select("-passwordHash");

  if (!student) {
    return res.status(404).json({
      success: false,
      message: "Student not found",
    });
  }
  return res.json({ success: true, student });
}

export async function listAllAchievements(req, res) {
  const { page, limit, skip } = parsePagination(req.query);
  const [achievements, total] = await Promise.all([
    Achievement.find()
      .populate("student", "fullName rollNumber department yearOfStudy email")
      .sort({ date: -1, _id: -1 })
      .skip(skip)
      .limit(limit),
    Achievement.countDocuments(),
  ]);
  return res.json({
    success: true,
    achievements,
    pagination: { page, limit, total },
  });
}

export async function updateAnyAchievement(req, res) {
  const achievement = await Achievement.findByIdAndUpdate(
    req.params.achievementId,
    { $set: req.validatedBody },
    { new: true, runValidators: true },
  );
  if (!achievement) {
    return res.status(404).json({
      success: false,
      message: "Achievement not found",
    });
  }
  return res.json({ success: true, achievement });
}

export async function deleteAnyAchievement(req, res) {
  const achievement = await Achievement.findByIdAndDelete(
    req.params.achievementId,
  );
  if (!achievement) {
    return res.status(404).json({
      success: false,
      message: "Achievement not found",
    });
  }
  return res.json({ success: true, message: "Achievement deleted" });
}
