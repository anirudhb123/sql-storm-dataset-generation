WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        0 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Id <> ur.UserId 
    WHERE 
        u.Reputation > (SELECT MAX(Reputation) FROM Users) - (ur.Level * 1000)
)
, PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
)
, UserBadges AS (
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
    u.DisplayName,
    u.Reputation,
    ur.Level AS ReputationLevel,
    pm.PostId,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    ROW_NUMBER() OVER (PARTITION BY ur.Level ORDER BY u.Reputation DESC) AS ReputationRank
FROM 
    Users u
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    PostMetrics pm ON u.Id = pm.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    ur.Level IS NOT NULL
ORDER BY 
    ReputationLevel, 
    ReputationRank;
