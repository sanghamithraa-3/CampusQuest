import { z } from "zod";

const achievementFields = {
  title: z.string().trim().min(1).max(160),
  category: z.string().trim().min(1).max(80),
  date: z.coerce.date(),
  description: z.string().trim().max(3000),
  certificateUrl: z
    .union([z.string().trim().max(2048), z.literal("")])
    .refine((value) => {
      if (!value) {
        return true;
      }
      try {
        const url = new URL(value);
        return url.protocol === "https:" || url.protocol === "http:";
      } catch {
        return false;
      }
    }, "Certificate URL must be a valid HTTP or HTTPS URL"),
};

export const createAchievementSchema = z
  .object({
    ...achievementFields,
    description: achievementFields.description.optional().default(""),
    certificateUrl: achievementFields.certificateUrl.optional().default(""),
  })
  .strict();

export const updateAchievementSchema = z
  .object({
    title: achievementFields.title.optional(),
    category: achievementFields.category.optional(),
    date: achievementFields.date.optional(),
    description: achievementFields.description.optional(),
    certificateUrl: achievementFields.certificateUrl.optional(),
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required",
  });
