WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank,
        (SELECT STRING_AGG(b.Name, ', ') 
         FROM Badges b 
         WHERE b.UserId = p.OwnerUserId) AS OwnerBadges,
        (SELECT COUNT(DISTINCT c.Id) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.OwnerBadges,
    rp.CommentCount
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 3 -- Top 3 posts in each tag based on score
ORDER BY 
    rp.CreationDate DESC
LIMIT 50; -- Limit to the latest 50 top posts
