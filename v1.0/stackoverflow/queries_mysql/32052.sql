
WITH RECURSIVE RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS TotalPosts,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId,
        (SELECT @row_number := 0) AS rn
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ra.BadgeCount, 0) AS RecentBadgeCount,
        ra.BadgeNames,
        ua.TotalViews,
        ua.TotalScore,
        ua.TotalPosts
    FROM 
        Users u
    JOIN 
        RecursiveUserActivity ua ON u.Id = ua.UserId
    LEFT JOIN 
        RecentBadges ra ON u.Id = ra.UserId
    WHERE 
        u.Reputation >= 1000
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalViews,
    tu.TotalScore,
    tu.RecentBadgeCount,
    tu.BadgeNames,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = tu.Id AND p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 MONTH)) AS RecentPostsCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = tu.Id AND c.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 MONTH)) AS RecentCommentsCount
FROM 
    TopUsers tu
WHERE 
    tu.TotalScore > 0
ORDER BY 
    tu.TotalScore DESC
LIMIT 10;
