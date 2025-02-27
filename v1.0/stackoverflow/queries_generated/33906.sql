WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
),
AverageViewCount AS (
    SELECT 
        p.OwnerUserId,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        c.PostId
)
SELECT 
    p.Title,
    p.Id AS PostId,
    U.DisplayName AS OwnerDisplayName,
    COALESCE(uv.AvgViewCount, 0) AS OwnerAvgViewCount,
    ub.BadgeCount,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount,
    ph.Level AS PostLevel
FROM 
    Posts p
JOIN 
    Users U ON p.OwnerUserId = U.Id
LEFT JOIN 
    AverageViewCount uv ON U.Id = uv.OwnerUserId
LEFT JOIN 
    UserBadges ub ON U.Id = ub.UserId
LEFT JOIN 
    RecentComments rc ON p.Id = rc.PostId
LEFT JOIN 
    RecursivePostHierarchy ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate > NOW() - INTERVAL '1 year'
    AND (p.ViewCount IS NOT NULL AND p.ViewCount > 100)
ORDER BY 
    OwnerAvgViewCount DESC, 
    p.ViewCount DESC
OFFSET 0 ROWS
FETCH NEXT 50 ROWS ONLY;
