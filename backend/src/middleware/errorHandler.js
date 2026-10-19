export function errorHandler(error, req, res, next) {
  if (res.headersSent) {
    return next(error);
  }

  if (error?.code === 11000) {
    return res.status(409).json({
      success: false,
      message: "An account with that email or roll number already exists",
    });
  }

  if (error?.status === 403) {
    return res.status(403).json({
      success: false,
      message: "Origin is not allowed",
    });
  }

  if (error?.name === "ValidationError" || error?.name === "CastError") {
    return res.status(400).json({
      success: false,
      message: "Request data is invalid",
    });
  }

  console.error("Request failed:", error);
  return res.status(500).json({
    success: false,
    message: "An unexpected server error occurred",
  });
}
