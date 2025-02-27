WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.OwnerUserId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
),
UserBadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    ur.TotalReputation,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
LEFT JOIN 
    UserBadgeCount ub ON u.Id = ub.UserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    AND (p.Title IS NOT NULL AND LENGTH(p.Title) > 10)
    AND (ur.TotalReputation IS NOT NULL OR ur.TotalReputation > 500)
GROUP BY 
    p.Id, u.DisplayName, ur.TotalReputation, cp.CloseCount, ub.BadgeCount, ub.HighestBadgeClass
ORDER BY 
    CloseCount DESC, PostRank ASC;
