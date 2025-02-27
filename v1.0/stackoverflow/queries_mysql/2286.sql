
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
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
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
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId AND v.VoteTypeId = 2 
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    RankedPosts bp ON u.Id = bp.OwnerUserId AND bp.ScoreRank <= 5
LEFT JOIN 
    (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(bp.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
     WHERE 
         CHAR_LENGTH(bp.Tags) - CHAR_LENGTH(REPLACE(bp.Tags, '><', '')) >= numbers.n - 1) AS t ON true
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(bp.PostId) > 0 OR COUNT(c.Id) > 0
ORDER BY 
    Upvotes DESC, CommentCount DESC;
