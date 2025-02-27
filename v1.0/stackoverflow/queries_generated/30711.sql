WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        LastAccessDate,
        DisplayName,
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
        u.LastAccessDate,
        u.DisplayName,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE ur ON u.Reputation > ur.Reputation
    WHERE 
        ur.Level < 5
),
TopUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputationCTE
),
PostInsights AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 3600) AS AvgPostAgeInHours
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopPosts AS (
    SELECT 
        ps.OwnerUserId,
        ps.TotalPosts,
        ps.PositiveScoreCount,
        ps.AvgPostAgeInHours,
        ROW_NUMBER() OVER (ORDER BY ps.PositiveScoreCount DESC) AS PostRank
    FROM 
        PostInsights ps
    JOIN 
        TopUsers tu ON ps.OwnerUserId = tu.Id
    WHERE 
        tu.Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tp.TotalPosts,
    tp.PositiveScoreCount,
    tp.AvgPostAgeInHours,
    CASE 
        WHEN tp.TotalPosts > 50 THEN 'High Activity'
        WHEN tp.TotalPosts BETWEEN 20 AND 50 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.Id = b.UserId AND b.Class = 1  -- Gold Badge
JOIN 
    TopPosts tp ON tu.Id = tp.OwnerUserId
ORDER BY 
    tu.Reputation DESC, tp.PositiveScoreCount DESC;
