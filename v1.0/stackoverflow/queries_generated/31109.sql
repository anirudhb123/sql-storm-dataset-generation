WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
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
        u.CreationDate,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputation ur ON u.Reputation > ur.Reputation AND ur.Level < 5
    WHERE 
        u.CreationDate < CURRENT_DATE - INTERVAL '365 days'
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ps.TotalPosts,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.TotalScore,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    ur.Level AS ReputationLevel,
    (SELECT 
         COUNT(*) 
     FROM 
         Votes v 
     WHERE 
         v.UserId = u.Id 
         AND v.CreationDate >= CURRENT_DATE - INTERVAL '7 days') AS RecentVotes
FROM 
    Users u
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    UserReputation ur ON u.Id = ur.Id
WHERE 
    u.Reputation > 100
    AND (rp.ViewCount IS NULL OR rp.ViewCount > 10)
ORDER BY 
    u.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 50;

-- Note:
-- This query retrieves users with a reputation over 100, their post statistics,
-- the most recent post information filtered by views, and includes a recursive CTE
-- for users with a high reputation and a summary of their voting behavior in the last week.
