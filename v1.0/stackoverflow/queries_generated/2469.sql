WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), 
TopPostLink AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkTypeName
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    WHERE 
        lt.Name IN ('Linked', 'Duplicate')
)
SELECT 
    u.DisplayName,
    us.TotalPosts,
    us.TotalViews,
    us.AverageScore,
    rp.Title AS TopPostTitle,
    rp.ViewCount AS TopPostViews,
    COALESCE(pl.LinkTypeName, 'No Link') AS PostLinkType
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    TopPostLink pl ON pl.PostId = rp.Id
WHERE 
    us.AverageScore > 5
ORDER BY 
    us.TotalViews DESC;
