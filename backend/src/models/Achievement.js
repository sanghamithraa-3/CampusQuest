import mongoose from "mongoose";

const achievementSchema = new mongoose.Schema(
  {
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 160,
    },
    category: {
      type: String,
      required: true,
      trim: true,
      maxlength: 80,
    },
    date: {
      type: Date,
      required: true,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 3000,
      default: "",
    },
    certificateUrl: {
      type: String,
      trim: true,
      maxlength: 2048,
      default: "",
    },
  },
  { timestamps: true },
);

achievementSchema.index({ student: 1, date: -1 });

export const Achievement = mongoose.model("Achievement", achievementSchema);
