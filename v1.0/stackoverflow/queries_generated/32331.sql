WITH RECURSIVE UserRank AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        1 AS RankLevel,
        u.CreationDate
    FROM Users u
    WHERE u.Reputation > 1000  -- Starting point for rank

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ur.RankLevel + 1,
        u.CreationDate
    FROM Users u
    INNER JOIN UserRank ur ON u.Reputation > ur.Reputation
    WHERE ur.RankLevel < 10  -- Limit the level of recursion
)

SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    UR.DisplayName AS TopUser,
    UR.Reputation AS UserReputation
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
LEFT JOIN UserRank UR ON p.OwnerUserId = UR.Id
WHERE p.Score > 0
  AND p.CreationDate > NOW() - INTERVAL '1 YEAR'
  AND (p.Tags LIKE '%SQL%' OR p.Title LIKE '%SQL%')
GROUP BY 
    p.Id, UR.DisplayName, UR.Reputation
HAVING 
    COUNT(c.Id) > 5  -- Only include posts with more than 5 comments
ORDER BY 
    p.Score DESC,
    TotalBounty DESC;
