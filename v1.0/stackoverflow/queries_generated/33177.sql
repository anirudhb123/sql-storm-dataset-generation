WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Depth + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
RecentPostActivity AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM 
        Posts p
)
SELECT 
    u.UserId,
    u.DisplayName,
    pa.PostId,
    pa.Title AS LatestPost,
    pa.ViewCount,
    ph.Depth AS PostDepth,
    ta.TagName,
    ua.PostCount AS UserPostCount,
    ua.TotalBounty AS UserTotalBounty
FROM 
    UserActivity ua
JOIN 
    RecentPostActivity pa ON ua.UserId = pa.OwnerUserId
LEFT JOIN 
    PostHierarchy ph ON pa.PostId = ph.PostId
LEFT JOIN 
    TagUsage ta ON pa.Title LIKE '%' || ta.TagName || '%'
WHERE 
    pa.ActivityRank = 1
ORDER BY 
    ua.TotalBounty DESC, 
    pa.ViewCount DESC
LIMIT 50;
