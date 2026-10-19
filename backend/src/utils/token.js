import jwt from "jsonwebtoken";

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret || Buffer.byteLength(secret, "utf8") < 32) {
    throw new Error("JWT_SECRET must contain at least 32 bytes");
  }
  return secret;
}

export function createAccessToken(user) {
  return jwt.sign(
    { role: user.role },
    getJwtSecret(),
    { subject: user.id, expiresIn: "1d" },
  );
}

export function verifyAccessToken(token) {
  return jwt.verify(token, getJwtSecret());
}
