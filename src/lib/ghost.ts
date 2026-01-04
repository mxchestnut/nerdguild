import GhostContentAPI from '@tryghost/content-api';

// Initialize Ghost API
const api = new GhostContentAPI({
  url: import.meta.env.GHOST_API_URL || 'https://nerd-church-1.ghost.io',
  key: import.meta.env.GHOST_CONTENT_API_KEY || '74d731fefda01e572f30461b2c',
  version: 'v5.0'
});

export interface GhostPost {
  id: string;
  title: string;
  slug: string;
  html: string;
  excerpt: string;
  custom_excerpt?: string;
  plaintext?: string;
  published_at: string;
  tags?: Array<{ name: string; slug: string }>;
  primary_tag?: { name: string; slug: string } | null;
}

/**
 * Get a short excerpt/snippet for display
 */
export function getExcerpt(post: GhostPost, maxLength = 150): string {
  // Use custom excerpt if available
  if (post.custom_excerpt) {
    return post.custom_excerpt;
  }
  
  // Use Ghost's auto-generated excerpt
  if (post.excerpt && post.excerpt.length <= maxLength) {
    return post.excerpt;
  }
  
  // Truncate excerpt if too long
  if (post.excerpt && post.excerpt.length > maxLength) {
    return post.excerpt.substring(0, maxLength).trim() + '...';
  }
  
  // Fallback to truncated plaintext
  if (post.plaintext) {
    return post.plaintext.substring(0, maxLength).trim() + '...';
  }
  
  return '';
}

/**
 * Fetch all posts from Ghost
 */
export async function getPosts(limit = 15): Promise<GhostPost[]> {
  try {
    const posts = await api.posts.browse({
      limit,
      include: ['tags', 'authors'],
      order: 'published_at DESC'
    });
    return posts as GhostPost[];
  } catch (error) {
    console.error('Error fetching Ghost posts:', error);
    return [];
  }
}

/**
 * Fetch posts by tag
 */
export async function getPostsByTag(tagSlug: string, limit = 6): Promise<GhostPost[]> {
  try {
    const posts = await api.posts.browse({
      limit,
      filter: `tag:${tagSlug}`,
      include: ['tags', 'authors'],
      order: 'published_at DESC'
    });
    return posts as GhostPost[];
  } catch (error) {
    console.error(`Error fetching posts for tag ${tagSlug}:`, error);
    return [];
  }
}

/**
 * Format Ghost date to readable format
 */
export function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric', 
    year: 'numeric' 
  });
}

/**
 * Get tags as comma-separated string
 */
export function getTagsString(post: GhostPost): string {
  if (!post.tags || post.tags.length === 0) return '';
  return post.tags.slice(0, 2).map(tag => tag.name).join(', ');
}
