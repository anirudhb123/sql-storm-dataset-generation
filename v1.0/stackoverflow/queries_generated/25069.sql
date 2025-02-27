WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN v.Id IS NOT NULL THEN 1 END) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Only count upvotes
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '"' FROM tag_array) -- Extract tags as array
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filtering for posts in the last year
    GROUP BY 
        p.Id, U.DisplayName
),

PostScoring AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        rp.Tags,
        -- Calculate a score metric based on score, view count, and user reputation
        (rp.Score * 0.5 + rp.ViewCount * 0.3 + COALESCE(u.Reputation, 0) * 0.2) AS FinalScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.VoteCount,
    ps.Tags,
    ps.FinalScore
FROM 
    PostScoring ps
WHERE 
    ps.FinalScore IS NOT NULL
ORDER BY 
    ps.FinalScore DESC -- Ranking by the calculated score
LIMIT 10; -- Limit results to top 10 posts
