WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL '1 year')
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= (NOW() - INTERVAL '6 months')
    GROUP BY 
        b.UserId
),

HighScoringBlogs AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = (SELECT Id FROM PostTypes WHERE Name = 'Wiki') 
        AND p.Score > 100
),

ClosedPostDetails AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.Comment AS CloseReason, 
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.Comment
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'No badges') AS BadgeNames,
    p.ViewCount,
    p.Title,
    p.CreationDate,
    ph.CloseReason,
    ph.CloseCount
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId AND p.Rank <= 5
LEFT JOIN 
    ClosedPostDetails ph ON ph.PostId = p.PostId
WHERE 
    u.Reputation > 100 
    AND u.CreationDate < (NOW() - INTERVAL '1 year')
    AND (p.ViewCount IS NOT NULL OR ph.CloseCount IS NOT NULL)
ORDER BY 
    u.Reputation DESC,
    p.Score DESC NULLS LAST
LIMIT 100;

-- Additional A/B testing for edge cases
UNION ALL

SELECT 
    -1 AS UserId,
    'Anonymous' AS DisplayName,
    0 AS BadgeCount,
    'N/A' AS BadgeNames,
    0 AS ViewCount,
    p.Title,
    p.CreationDate,
    NULL AS CloseReason,
    0 AS CloseCount
FROM 
    HighScoringBlogs p
WHERE 
    NOT EXISTS (SELECT 1 FROM Users WHERE Reputation > 200);

