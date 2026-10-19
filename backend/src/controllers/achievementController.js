import { Achievement } from "../models/Achievement.js";

export async function listMyAchievements(req, res) {
  const achievements = await Achievement.find({ student: req.user.id }).sort({
    date: -1,
    _id: -1,
  });
  return res.json({ success: true, achievements });
}

export async function createAchievement(req, res) {
  const achievement = await Achievement.create({
    ...req.validatedBody,
    student: req.user.id,
  });
  return res.status(201).json({ success: true, achievement });
}

export async function getMyAchievement(req, res) {
  const achievement = await Achievement.findOne({
    _id: req.params.achievementId,
    student: req.user.id,
  });
  if (!achievement) {
    return res.status(404).json({
      success: false,
      message: "Achievement not found",
    });
  }
  return res.json({ success: true, achievement });
}

export async function updateMyAchievement(req, res) {
  const achievement = await Achievement.findOneAndUpdate(
    {
      _id: req.params.achievementId,
      student: req.user.id,
    },
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

export async function deleteMyAchievement(req, res) {
  const achievement = await Achievement.findOneAndDelete({
    _id: req.params.achievementId,
    student: req.user.id,
  });
  if (!achievement) {
    return res.status(404).json({
      success: false,
      message: "Achievement not found",
    });
  }
  return res.json({ success: true, message: "Achievement deleted" });
}
