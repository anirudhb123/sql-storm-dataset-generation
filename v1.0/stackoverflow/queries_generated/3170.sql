WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalScore,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM UserActivity
)
SELECT 
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    tu.TotalViews,
    tu.TotalScore,
    CASE 
        WHEN tu.Rank <= 5 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM TopUsers tu
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM Badges 
    WHERE Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY UserId
) b ON tu.UserId = b.UserId
WHERE tu.TotalScore > (
    SELECT AVG(TotalScore) FROM TopUsers
) 
ORDER BY tu.TotalScore DESC
LIMIT 10;

SELECT DISTINCT 
    CASE 
        WHEN t.TagName IS NULL THEN 'No Tag' 
        ELSE t.TagName 
    END AS TagName,
    COUNT(p.Id) AS PostCount
FROM Tags t
FULL OUTER JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
GROUP BY t.TagName
HAVING COUNT(p.Id) > 5
ORDER BY PostCount DESC
LIMIT 5;
