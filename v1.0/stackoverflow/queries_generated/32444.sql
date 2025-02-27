WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
        AND p.Score > 0
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId IN (2, 3) -- considering only upvotes and downvotes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
HighEngagementPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.ViewCount,
        r.CreationDate,
        r.Tags,
        i.CommentCount,
        i.VoteCount
    FROM 
        RankedPosts r
    INNER JOIN 
        PostInteractions i ON r.PostId = i.PostId
    WHERE 
        i.CommentCount > 5 OR i.VoteCount > 10
)
SELECT 
    h.PostId,
    h.Title,
    h.Score,
    h.ViewCount,
    h.CreationDate,
    h.Tags,
    CONCAT('Total Engagement: ', (h.CommentCount + h.VoteCount)) AS EngagementSummary
FROM 
    HighEngagementPosts h
WHERE 
    h.Rank <= 5
ORDER BY 
    h.Score DESC
LIMIT 10;

-- This query retrieves a list of top-ranked posts based on scores 
-- from the last month that have significant user engagement through comments or votes.
-- It ranks posts by their type and selects top posts having engagement metrics.
