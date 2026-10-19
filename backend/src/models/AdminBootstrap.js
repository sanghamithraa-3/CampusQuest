import mongoose from "mongoose";

const adminBootstrapSchema = new mongoose.Schema(
  {
    _id: {
      type: String,
      required: true,
    },
  },
  { versionKey: false },
);

export const AdminBootstrap = mongoose.model(
  "AdminBootstrap",
  adminBootstrapSchema,
);
