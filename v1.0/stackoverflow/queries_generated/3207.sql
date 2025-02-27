WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
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
        RANK() OVER (ORDER BY us.Reputation DESC) AS Rank
    FROM 
        UserStats us
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

-- This query retrieves the top 10 users by reputation who have posted in the last year,
-- along with their most recent post title. If a user has no posts, 'No Posts Yet' is shown,
-- and only users with above-average reputation are included.
