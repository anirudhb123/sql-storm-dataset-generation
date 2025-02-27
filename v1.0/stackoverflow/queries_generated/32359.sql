WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000  -- Starting level with user reputation greater than 1000

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        Level + 1
    FROM 
        Users u
    INNER JOIN UserReputation ur ON u.Id = ur.UserId
    WHERE 
        u.Reputation > ur.Reputation AND ur.Level < 5  -- Recursively find higher reputation users, limiting depth to 5
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerName,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    COUNT(DISTINCT c.Id) AS CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(h.Id) AS EditHistoryCount,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserRanking,
    CASE 
        WHEN p.Score > 100 THEN 'High Score'
        WHEN p.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- Count BountyStart votes
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'  -- Join on tags based on Tags string
LEFT JOIN 
    PostHistory h ON p.Id = h.PostId 
WHERE 
    p.CreatedDate >= NOW() - interval '1 year'  -- Only include posts from the last year
GROUP BY 
    p.Id, u.Id
HAVING 
    COUNT(DISTINCT c.Id) > 5  -- Only include posts with more than 5 comments
ORDER BY 
    u.Reputation DESC, p.Score DESC  -- Order by user reputation and then post score
LIMIT 100;  -- Limit the result to the top 100
