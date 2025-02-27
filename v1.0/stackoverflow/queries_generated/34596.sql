WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        OwnerUserId,
        PostTypeId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostScore AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(u.Reputation, 0) AS UserReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
ActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        OwnerUserId
),
QualifiedBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Only Gold badges
    GROUP BY 
        b.UserId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerName,
    COALESCE(q.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(a.PostCount, 0) AS RecentPostCount,
    COALESCE(a.TotalScore, 0) AS RecentTotalScore,
    r.Level AS PostLevel
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    QualifiedBadges q ON u.Id = q.UserId
LEFT JOIN 
    ActiveUsers a ON u.Id = a.OwnerUserId
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.Id
WHERE 
    p.Score > 0 
    AND p.ViewCount > 100 
    AND u.Reputation > 500
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;
