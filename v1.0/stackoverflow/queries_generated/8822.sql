WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
)

SELECT 
    up.DisplayName,
    up.Reputation,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    AVG(rp.ViewCount) AS AvgViewCount,
    AVG(rp.CommentCount) AS AvgCommentCount,
    MAX(rp.RankPerUser) AS MaxPostRank
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
WHERE 
    up.Reputation > 1000
GROUP BY 
    up.Id, up.DisplayName, up.Reputation
ORDER BY 
    TotalScore DESC
LIMIT 10;
