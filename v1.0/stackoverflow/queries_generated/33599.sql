WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        0 AS Level,
        p.OwnerUserId
    FROM 
        Posts p 
    WHERE 
        p.ParentId IS NULL -- Top-level posts (Questions only)

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.ViewCount,
        a.Score,
        c.Level + 1,
        a.OwnerUserId
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE c ON a.ParentId = c.PostId
)

SELECT 
    u.DisplayName,
    COUNT(b.Id) AS BadgeCount,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    AVG(rp.Score) AS AverageScore,
    MAX(rp.ViewCount) AS MaxViewCount,
    STRING_AGG(DISTINCT p.Tags, ', ') AS UniqueTags
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    RecursivePostCTE rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
WHERE 
    u.Reputation > 100 -- Only users with reputation greater than 100
    AND rp.Level = 0 -- Consider only top-level posts
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(rp.PostId) > 5 -- Users must have contributed to more than 5 questions
ORDER BY 
    AverageScore DESC, 
    TotalPosts DESC;
