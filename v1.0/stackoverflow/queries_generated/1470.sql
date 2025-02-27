WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        rp.OwnerUserId,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.AnswerCount) AS TotalAnswers,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation u ON rp.OwnerUserId = u.UserId
    LEFT JOIN 
        (SELECT UserId, COUNT(DISTINCT Id) AS BadgeCount 
         FROM Badges 
         GROUP BY UserId) ub ON rp.OwnerUserId = ub.UserId
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    ps.OwnerUserId,
    ps.TotalScore,
    ps.TotalAnswers,
    ps.UserReputation,
    ps.UserBadgeCount,
    CASE 
        WHEN ps.UserReputation >= 1000 THEN 'Gold'
        WHEN ps.UserReputation >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS ReputationTier
FROM 
    PostStats ps
WHERE 
    ps.TotalAnswers > 5
ORDER BY 
    ps.TotalScore DESC
LIMIT 10;

-- Perform a union of users who have contributed less than 5 answers but have high reputations.
UNION ALL 

SELECT 
    u.Id AS OwnerUserId,
    0 AS TotalScore,
    0 AS TotalAnswers,
    u.Reputation AS UserReputation,
    COALESCE(badgeCount.BadgeCount, 0) AS UserBadgeCount,
    CASE 
        WHEN u.Reputation >= 1000 THEN 'Gold'
        WHEN u.Reputation >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS ReputationTier
FROM 
    Users u 
LEFT JOIN 
    (SELECT UserId, COUNT(DISTINCT Id) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) badgeCount ON u.Id = badgeCount.UserId
WHERE 
    u.Id NOT IN (SELECT OwnerUserId FROM PostStats WHERE TotalAnswers > 5)
AND 
    u.Reputation > 500 
ORDER BY 
    u.Reputation DESC
LIMIT 10;
