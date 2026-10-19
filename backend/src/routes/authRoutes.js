import { Router } from "express";
import rateLimit from "express-rate-limit";
import {
  getCurrentUser,
  login,
  registerStudent,
} from "../controllers/authController.js";
import { authenticate } from "../middleware/authenticate.js";
import { validateBody } from "../middleware/validateBody.js";
import { loginSchema, registrationSchema } from "../utils/validation.js";

const router = Router();
const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: "draft-8",
  legacyHeaders: false,
});

router.post(
  "/register",
  authRateLimit,
  validateBody(registrationSchema),
  registerStudent,
);
router.post("/login", authRateLimit, validateBody(loginSchema), login);
router.get("/me", authenticate, getCurrentUser);

export default router;
