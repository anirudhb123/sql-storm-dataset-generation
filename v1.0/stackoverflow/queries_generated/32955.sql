WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 0

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation * 1.1 AS Reputation, 
        u.CreationDate,
        Level + 1
    FROM 
        Users u
    JOIN 
        UserReputationCTE cte ON u.Reputation < cte.Reputation AND cte.Level < 5
),

RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 0
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    r.Level AS ReputationLevel,
    COALESCE(p.PostCount, 0) AS PostCount,
    COALESCE(r.Reputation, 0) AS AdjustedReputation,
    COALESCE(cp.Views, 0) AS TotalViews
FROM 
    Users u
LEFT JOIN 
    (SELECT UserId, COUNT(1) AS Views FROM Posts p GROUP BY p.OwnerUserId) cp ON u.Id = cp.UserId
LEFT JOIN 
    UserReputationCTE r ON u.Id = r.UserId
LEFT JOIN 
    TopUsers p ON u.Id = p.UserId
WHERE 
    u.Reputation IS NOT NULL
ORDER BY 
    u.Reputation DESC;

-- The query uses a recursive CTE to calculate adjusted user reputation, 
-- a CTE to fetch recent posts by users in the last 30 days, 
-- and aggregates scores from posts to identify top users.
-- The final select compiles user data including views and adjusted reputation levels based on their activity.
