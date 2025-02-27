
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        BadgeCount,
        PostCount,
        TotalViews,
        TotalScore,
        @rank := @rank + 1 AS Rank
    FROM 
        UserStatistics, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
)

SELECT 
    u.UserId,
    u.Reputation,
    u.BadgeCount,
    u.PostCount,
    u.TotalViews,
    u.TotalScore,
    t.Rank
FROM 
    UserStatistics u
JOIN 
    TopUsers t ON u.UserId = t.UserId
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;
