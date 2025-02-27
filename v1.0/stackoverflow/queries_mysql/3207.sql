
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        @rn := IF(@prevOwnerUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevOwnerUserId := p.OwnerUserId
    FROM 
        Posts p, (SELECT @rn := 0, @prevOwnerUserId := NULL) AS var
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 0
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.TotalViews,
        us.TotalScore,
        @rank := @rank + 1 AS Rank
    FROM 
        UserStats us, (SELECT @rank := 0) AS var
    ORDER BY 
        us.Reputation DESC
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalViews,
    tu.TotalScore,
    COALESCE(rp.Title, 'No Posts Yet') AS RecentPostTitle
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    tu.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    tu.Rank
LIMIT 10;
