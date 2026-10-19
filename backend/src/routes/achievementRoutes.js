import { Router } from "express";
import {
  createAchievement,
  deleteMyAchievement,
  getMyAchievement,
  listMyAchievements,
  updateMyAchievement,
} from "../controllers/achievementController.js";
import { authenticate } from "../middleware/authenticate.js";
import { authorize } from "../middleware/authorize.js";
import { validateBody } from "../middleware/validateBody.js";
import { validateObjectId } from "../utils/validateObjectId.js";
import {
  createAchievementSchema,
  updateAchievementSchema,
} from "../utils/achievementValidation.js";

const router = Router();
router.use(authenticate, authorize("student"));
router.get("/", listMyAchievements);
router.post("/", validateBody(createAchievementSchema), createAchievement);
router.get(
  "/:achievementId",
  validateObjectId("achievementId"),
  getMyAchievement,
);
router.patch(
  "/:achievementId",
  validateObjectId("achievementId"),
  validateBody(updateAchievementSchema),
  updateMyAchievement,
);
router.delete(
  "/:achievementId",
  validateObjectId("achievementId"),
  deleteMyAchievement,
);

export default router;
