import { z } from "zod";

const emailSchema = z
  .string()
  .trim()
  .email()
  .max(254)
  .transform((email) => email.toLowerCase());

const registrationPasswordSchema = z
  .string()
  .min(12)
  .max(72)
  .refine((password) => Buffer.byteLength(password, "utf8") <= 72, {
    message: "Password must not exceed 72 UTF-8 bytes",
  });

const loginPasswordSchema = z
  .string()
  .min(1)
  .max(72)
  .refine((password) => Buffer.byteLength(password, "utf8") <= 72, {
    message: "Password must not exceed 72 UTF-8 bytes",
  });

export const registrationSchema = z
  .object({
    fullName: z.string().trim().min(1).max(120),
    rollNumber: z
      .string()
      .trim()
      .min(1)
      .max(30)
      .transform((rollNumber) => rollNumber.toUpperCase()),
    department: z.string().trim().min(1).max(100),
    yearOfStudy: z.coerce.number().int().min(1).max(6),
    email: emailSchema,
    password: registrationPasswordSchema,
  })
  .strict();

export const loginSchema = z
  .object({
    email: emailSchema,
    password: loginPasswordSchema,
  })
  .strict();

export const adminCredentialsSchema = z.object({
  email: emailSchema,
  password: registrationPasswordSchema,
});
