import { Router } from "express";
import {
  deleteAnyAchievement,
  listAllAchievements,
  listStudents,
  setStudentActiveState,
  updateAnyAchievement,
} from "../controllers/adminController.js";
import { authenticate } from "../middleware/authenticate.js";
import { authorize } from "../middleware/authorize.js";
import { validateBody } from "../middleware/validateBody.js";
import {
  updateAchievementSchema,
} from "../utils/achievementValidation.js";
import { validateObjectId } from "../utils/validateObjectId.js";
import { z } from "zod";

const router = Router();
router.use(authenticate, authorize("admin"));
router.get("/students", listStudents);
router.patch(
  "/students/:studentId",
  validateObjectId("studentId"),
  validateBody(z.object({ isActive: z.boolean() }).strict()),
  setStudentActiveState,
);
router.get("/achievements", listAllAchievements);
router.patch(
  "/achievements/:achievementId",
  validateObjectId("achievementId"),
  validateBody(updateAchievementSchema),
  updateAnyAchievement,
);
router.delete(
  "/achievements/:achievementId",
  validateObjectId("achievementId"),
  deleteAnyAchievement,
);

export default router;
