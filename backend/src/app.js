import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import authRoutes from "./routes/authRoutes.js";
import achievementRoutes from "./routes/achievementRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";
import portfolioRoutes from "./routes/portfolioRoutes.js";
import { errorHandler } from "./middleware/errorHandler.js";

dotenv.config();

const app = express();
const allowedOrigins = new Set(
  (process.env.CORS_ORIGINS ??
    "http://localhost:7357,http://127.0.0.1:7357")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean),
);

app.use(helmet());
app.use(
  cors({
    origin(origin, callback) {
      if (!origin || allowedOrigins.has(origin)) {
        return callback(null, true);
      }
      const error = new Error("Origin is not allowed by CORS");
      error.status = 403;
      return callback(error);
    },
  }),
);
app.use(express.json());

app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "Campus Quest API is running",
  });
});

app.use("/api/auth", authRoutes);
app.use("/api/achievements", achievementRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/portfolio", portfolioRoutes);
app.use(errorHandler);

export default app;
