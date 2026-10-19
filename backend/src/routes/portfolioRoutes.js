import { Router } from "express";
import {
  downloadMyPortfolio,
  downloadStudentPortfolio,
  getMyPortfolio,
  getStudentPortfolio,
} from "../controllers/portfolioController.js";
import { authenticate } from "../middleware/authenticate.js";
import { authorize } from "../middleware/authorize.js";
import { validateObjectId } from "../utils/validateObjectId.js";

const router = Router();
router.use(authenticate);
router.get("/me", authorize("student"), getMyPortfolio);
router.get("/me/pdf", authorize("student"), downloadMyPortfolio);
router.get(
  "/students/:studentId",
  authorize("admin"),
  validateObjectId("studentId"),
  getStudentPortfolio,
);
router.get(
  "/students/:studentId/pdf",
  authorize("admin"),
  validateObjectId("studentId"),
  downloadStudentPortfolio,
);

export default router;
