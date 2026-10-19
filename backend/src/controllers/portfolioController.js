import { getPortfolio } from "../services/portfolioService.js";
import { streamPortfolioPdf } from "../services/portfolioPdf.js";

function filenameFor(student) {
  const identity = student.rollNumber || student.id;
  const safeIdentity = identity.replace(/[^a-zA-Z0-9_-]/g, "-");
  return `campus-quest-portfolio-${safeIdentity}.pdf`;
}

async function sendPortfolio(req, res, studentId, asPdf) {
  const portfolio = await getPortfolio(studentId);
  if (!portfolio) {
    return res.status(404).json({
      success: false,
      message: "Student not found",
    });
  }

  if (!asPdf) {
    return res.json({ success: true, portfolio });
  }

  res.setHeader("Content-Type", "application/pdf");
  res.setHeader(
    "Content-Disposition",
    `attachment; filename="${filenameFor(portfolio.student)}"`,
  );
  streamPortfolioPdf(portfolio, res);
}

export async function getMyPortfolio(req, res) {
  return sendPortfolio(req, res, req.user.id, false);
}

export async function downloadMyPortfolio(req, res) {
  return sendPortfolio(req, res, req.user.id, true);
}

export async function getStudentPortfolio(req, res) {
  return sendPortfolio(req, res, req.params.studentId, false);
}

export async function downloadStudentPortfolio(req, res) {
  return sendPortfolio(req, res, req.params.studentId, true);
}
