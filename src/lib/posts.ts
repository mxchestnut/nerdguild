import { getCollection } from 'astro:content';

/**
 * Get all published posts sorted by date (newest first)
 */
export async function getAllPosts() {
  const posts = await getCollection('posts', ({ data }) => {
    return data.draft !== true;
  });
  
  return posts.sort((a, b) => 
    b.data.publishedAt.getTime() - a.data.publishedAt.getTime()
  );
}

/**
 * Get posts by category
 */
export async function getPostsByCategory(category: string, limit?: number) {
  const posts = await getCollection('posts', ({ data }) => {
    return data.draft !== true && data.category === category;
  });
  
  const sorted = posts.sort((a, b) => 
    b.data.publishedAt.getTime() - a.data.publishedAt.getTime()
  );
  
  return limit ? sorted.slice(0, limit) : sorted;
}

/**
 * Format date to readable string
 */
export function formatDate(date: Date): string {
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric', 
    year: 'numeric' 
  });
}

/**
 * Get excerpt from content
 */
export function getExcerpt(content: string, maxLength = 150): string {
  const plainText = content.replace(/<[^>]*>/g, '').replace(/\n/g, ' ');
  if (plainText.length <= maxLength) return plainText;
  return plainText.substring(0, maxLength).trim() + '...';
}
