WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 AS Level
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
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE((SELECT COUNT(DISTINCT c.Id) 
                   FROM Comments c 
                   WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    u.DisplayName, 
    ps.Title AS PostTitle, 
    ps.ViewCount,
    ps.CommentCount,
    r.Level AS PostLevel,
    CASE WHEN u.TotalBountyAmount IS NULL THEN 0 ELSE u.TotalBountyAmount END AS TotalBounty
FROM 
    UserStats u
JOIN 
    TopPosts ps ON u.PostCount > 5
LEFT JOIN 
    RecursivePostHierarchy r ON ps.Id = r.Id
WHERE 
    u.BadgeCount > 3
ORDER BY 
    u.BadgeCount DESC, ps.ViewCount DESC
LIMIT 10;

-- Performance Benchmarking: 
-- - The recursive CTE `RecursivePostHierarchy` to organize posts in a parent-child format.
-- - The CTE `UserStats` aggregates user data to calculate post counts, badge counts, and total bounties.
-- - The `TopPosts` CTE ranks popular posts within the last 30 days based on view count.
-- - The final SELECT joins these CTEs, applying filters based on criteria and ordering by badge count and view count.
