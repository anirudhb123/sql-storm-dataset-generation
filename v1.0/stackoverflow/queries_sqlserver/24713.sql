
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 YEAR'
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    AVG(rp.Score) AS AverageScore,
    CASE 
        WHEN AVG(rp.ViewCount) IS NOT NULL THEN AVG(rp.ViewCount) 
        ELSE 0 END AS AverageViews,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    MAX(CASE WHEN b.Class = 1 THEN b.Date END) AS GoldBadgeDate 
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank <= 5
LEFT JOIN 
    Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (1, 2) 
LEFT JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
LEFT JOIN 
    Tags t ON t.Id = pl.RelatedPostId 
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id,
    u.DisplayName,
    u.Reputation
ORDER BY 
    TotalPosts DESC,
    Reputation DESC
OFFSET 5 ROWS 
FETCH NEXT 10 ROWS ONLY;
