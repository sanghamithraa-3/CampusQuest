import { User } from "../models/User.js";
import { verifyAccessToken } from "../utils/token.js";

export async function authenticate(req, res, next) {
  const authorization = req.get("authorization");
  const match = authorization?.match(/^Bearer\s+(\S+)$/i);

  if (!match) {
    return res.status(401).json({
      success: false,
      message: "Authentication is required",
    });
  }

  let claims;
  try {
    claims = verifyAccessToken(match[1]);
  } catch {
    return res.status(401).json({
      success: false,
      message: "Access token is invalid or expired",
    });
  }

  if (typeof claims !== "object" || typeof claims.sub !== "string") {
    return res.status(401).json({
      success: false,
      message: "Access token is invalid",
    });
  }

  const user = await User.findById(claims.sub);
  if (!user || !user.isActive) {
    return res.status(401).json({
      success: false,
      message: "Account is unavailable",
    });
  }

  req.user = user;
  return next();
}
