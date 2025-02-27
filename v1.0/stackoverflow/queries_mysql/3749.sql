
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, TotalPosts, PositivePosts, NegativePosts, AverageScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserStats
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Date AS AwardDate,
        @row_number := IF(@prev_user_id = b.UserId, @row_number + 1, 1) AS BadgeRank,
        @prev_user_id := b.UserId
    FROM 
        Badges b, (SELECT @row_number := 0, @prev_user_id := NULL) AS init
    ORDER BY 
        b.UserId, b.Date DESC
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.PositivePosts,
    tu.NegativePosts,
    tu.AverageScore,
    COALESCE(rb.BadgeName, 'No Recent Badge') AS RecentBadge,
    rb.AwardDate
FROM 
    TopUsers tu
LEFT JOIN 
    RecentBadges rb ON tu.UserId = rb.UserId AND rb.BadgeRank = 1
WHERE 
    tu.AverageScore IS NOT NULL
ORDER BY 
    tu.TotalPosts DESC;
