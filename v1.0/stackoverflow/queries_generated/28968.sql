WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
        ) t ON TRUE
    WHERE 
        p.PostTypeId = 1  -- We're only interested in Questions
        AND p.Score > 0   -- Only consider posts with a positive score
),
TopPosts AS (
    SELECT 
        r.* 
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5  -- Get top 5 posts per tag
),
PostWithBadges AS (
    SELECT 
        tp.*,
        COUNT(b.Id) AS BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Badges b ON tp.OwnerDisplayName = b.UserId
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.Score, tp.OwnerDisplayName, tp.TagName
)
SELECT 
    pwp.PostId,
    pwp.Title,
    pwp.Body,
    pwp.CreationDate,
    pwp.Score,
    pwp.OwnerDisplayName,
    pwp.TagName,
    pwp.BadgeCount
FROM 
    PostWithBadges pwp
ORDER BY 
    pwp.TagName, pwp.Score DESC;

This SQL query is designed to benchmark string processing by:

1. **Ranking Posts**: Selecting questions along with their tags and ranking them by their score, filtered to only include posts with a positive score.
  
2. **Finding Top Posts**: From the ranked results, it extracts the top 5 posts for each tag.
  
3. **Counting Badges**: It then counts the badges held by the owner of those posts.

4. **Final Selection**: Finally, it retrieves the relevant information sorted by tag name and score.

This provides a comprehensive view of how the posts with the highest engagement (scores) are represented across tags, along with acknowledging user contributions through badges.
