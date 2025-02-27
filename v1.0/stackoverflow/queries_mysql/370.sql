
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        TotalScore,
        AverageScore,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @row_num := 0) AS rn
    ORDER BY 
        TotalScore DESC
)
SELECT 
    tu.DisplayName,
    tu.TotalViews,
    tu.TotalScore,
    tu.AverageScore,
    COUNT(DISTINCT bh.Id) AS BadgeCount,
    GROUP_CONCAT(DISTINCT p.Title SEPARATOR ', ') AS TopPosts
FROM 
    TopUsers tu
LEFT JOIN 
    Badges bh ON tu.UserId = bh.UserId
LEFT JOIN 
    Posts p ON p.OwnerUserId = tu.UserId
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalViews, tu.TotalScore, tu.AverageScore
ORDER BY 
    tu.TotalScore DESC;
