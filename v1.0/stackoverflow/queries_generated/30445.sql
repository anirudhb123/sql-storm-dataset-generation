WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        0 AS Level
    FROM Users u
    WHERE u.Reputation > 100
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Reputation > 100 * (ur.Level + 1)
),
PostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts
    FROM Posts p
    GROUP BY p.OwnerUserId
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pc.TotalPosts, 0) AS TotalPosts,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount
    FROM Users u
    LEFT JOIN PostCounts pc ON u.Id = pc.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, pc.TotalPosts
),
ActiveUserStats AS (
    SELECT 
        mau.UserId,
        mau.DisplayName,
        mau.TotalPosts,
        mau.UpVoteCount,
        ur.Level AS ReputationLevel,
        ROW_NUMBER() OVER (ORDER BY mau.UpVoteCount DESC) AS VoteRank
    FROM MostActiveUsers mau
    JOIN UserReputation ur ON mau.UserId = ur.UserId
)
SELECT 
    a.UserId,
    a.DisplayName,
    a.TotalPosts,
    a.UpVoteCount,
    ur.Name AS ReputationLevelName,
    CASE 
        WHEN a.TotalPosts > 10 THEN 'High Activity'
        WHEN a.TotalPosts BETWEEN 5 AND 10 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM ActiveUserStats a
JOIN PostHistoryTypes ur ON a.ReputationLevel = ur.Id
WHERE a.UpVoteCount > 0
ORDER BY a.UpVoteCount DESC, a.TotalPosts DESC;
