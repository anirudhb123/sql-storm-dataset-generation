WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        LastAccessDate,
        CreationDate,
        1 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000
    UNION ALL
    SELECT 
        u.Id, 
        u.Reputation,
        u.LastAccessDate,
        u.CreationDate,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Reputation < ur.Reputation
    WHERE 
        ur.Level < 3  -- Limiting recursion depth
), 
PostMetrics AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        MAX(p.CreationDate) AS CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AcceptedAnswerId
), 
BadgeCount AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeAwardCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
HighScoringPosts AS (
    SELECT 
        pm.PostId, 
        pm.Title,
        pm.Score,
        pm.ViewCount,
        pm.CommentCount,
        COALESCE(bp.BadgeAwardCount, 0) AS BadgeCount,
        pu.UserId,
        pu.Reputation
    FROM 
        PostMetrics pm
    LEFT JOIN 
        BadgeCount bp ON pm.AcceptedAnswerId = bp.UserId
    LEFT JOIN 
        Users pu ON pm.AcceptedAnswerId = pu.Id
    WHERE 
        pm.Score > 10
)
SELECT 
    hsp.Title,
    hsp.Score,
    hsp.ViewCount,
    hsp.CommentCount,
    hsp.BadgeCount,
    ur.Reputation AS UserReputationLevel,
    CASE 
        WHEN ur.Reputation IS NOT NULL THEN 'Highlighted User'
        ELSE 'Regular User'
    END AS UserType,
    CASE 
        WHEN hsp.Score >= 50 THEN 'High Engagement'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    UserReputation ur ON hsp.UserId = ur.UserId
ORDER BY 
    hsp.Score DESC, 
    hsp.ViewCount DESC;

