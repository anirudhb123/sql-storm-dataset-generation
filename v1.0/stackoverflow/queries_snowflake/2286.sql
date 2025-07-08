
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank,
        p.OwnerUserId,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56'::TIMESTAMP)
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(v.Id) AS Upvotes,
    COUNT(c.Id) AS CommentCount,
    MAX(bp.Score) AS BestPostScore,
    MIN(bp.CreationDate) AS FirstPostDate,
    SUM(CASE 
            WHEN bp.ViewCount > 1000 THEN 1 
            ELSE 0 
        END) AS HighViewCountPosts,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId AND v.VoteTypeId = 2 
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    RankedPosts bp ON u.Id = bp.OwnerUserId AND bp.ScoreRank <= 5
LEFT JOIN 
    LATERAL SPLIT_TO_TABLE(SUBSTRING(bp.Tags, 2, LENGTH(bp.Tags) - 2), '><') AS t(TagName) ON true
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(bp.PostId) > 0 OR COUNT(c.Id) > 0
ORDER BY 
    Upvotes DESC, CommentCount DESC;
