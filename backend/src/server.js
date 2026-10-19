import dotenv from "dotenv";
import { connectDB } from "./config/db.js";
import app from "./app.js";

dotenv.config();

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    if (!process.env.JWT_SECRET || Buffer.byteLength(process.env.JWT_SECRET) < 32) {
      throw new Error("JWT_SECRET must contain at least 32 bytes");
    }
    if (
      process.env.NODE_ENV === "production" &&
      !process.env.CORS_ORIGINS
    ) {
      throw new Error("CORS_ORIGINS must be set in production");
    }
    await connectDB();

    app.listen(PORT, () => {
      console.log(`Server running at http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("Backend startup failed:", error.message);
    process.exit(1);
  }
}

startServer();