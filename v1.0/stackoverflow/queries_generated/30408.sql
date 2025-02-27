WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE ur ON u.Reputation = ur.Reputation / 2
)
, RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)
, UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.Views,
    COALESCE(rb.Badges, 'No Badges') AS Badges,
    rp.Title AS RecentPostTitle,
    rp.ViewCount AS RecentPostViewCount,
    CASE 
        WHEN rp.ViewCount IS NOT NULL THEN ROUND(COALESCE(100.0 * rp.ViewCount / NULLIF((
            SELECT 
                SUM(ViewCount) 
            FROM 
                Posts p2
            WHERE 
                p2.OwnerUserId = u.Id
        ), 0), 0), 2)
        ELSE 0
    END AS ViewPercentage
FROM 
    Users u
LEFT JOIN 
    UserBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- Additional Queries for Benchmarking
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AvgViewCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScores,
    SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScores
FROM 
    Posts p
INNER JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
HAVING 
    COUNT(p.Id) > 5
ORDER BY 
    AvgViewCount DESC;

SELECT 
    ph.PostId,
    COUNT(DISTINCT ph.UserId) AS EditorCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    PostHistory ph
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6, 24) -- Edit Title, Edit Body, Edit Tags, Suggested Edit Applied
GROUP BY 
    ph.PostId
HAVING 
    COUNT(DISTINCT ph.UserId) > 1
ORDER BY 
    LastEditDate DESC
LIMIT 5;

-- Use of string manipulation and NULL logic 
SELECT 
    p.Id,
    SUBSTRING(p.Title, 1, 50) || '...' AS ShortTitle,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(NULLIF(c.Text, ''), 'No comments yet') AS CommentText
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.ViewCount > 1000
ORDER BY 
    p.ViewCount DESC;
