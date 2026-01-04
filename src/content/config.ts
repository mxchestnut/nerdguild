import { defineCollection, z } from 'astro:content';

const postsCollection = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    publishedAt: z.date(),
    category: z.enum(['Hieroscope', 'The Beacon Project', 'Roots & Reach', 'Nerd Church', 'Nerd Guild']),
    tags: z.array(z.string()).optional(),
    draft: z.boolean().optional().default(false),
  }),
});

export const collections = {
  posts: postsCollection,
};
