import { z } from "zod";

export const profileSchema = z.object({
  full_name: z.string().trim().min(1).max(120),
  email: z.string().trim().toLowerCase().email().max(254),
  student_id: z.string().trim().max(40).optional(),
});

export const moodleCredentialsSchema = z.object({
  site_url: z.string().min(1).max(300),
  username: z.string().trim().min(1).max(100),
  password: z.string().min(1).max(256),
});

export const moodleSignInSchema = moodleCredentialsSchema.extend({
  profile: profileSchema.optional(),
});

export const googleSignInSchema = z.object({
  id_token: z.string().min(1).max(4096),
  profile: profileSchema.optional(),
});

export const googleConnectSchema = z.object({
  id_token: z.string().min(1).max(4096),
});
