import mongoose from "mongoose";

export function validateObjectId(parameterName) {
  return (req, res, next) => {
    if (!mongoose.isValidObjectId(req.params[parameterName])) {
      return res.status(400).json({
        success: false,
        message: `Invalid ${parameterName}`,
      });
    }
    return next();
  };
}
