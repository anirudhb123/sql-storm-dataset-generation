WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalBadgeClass,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserReputation
),
RecentActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS RecentPostCount,
        MAX(p.CreationDate) AS LastActiveDate
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalBadgeClass,
    tu.TotalBounties,
    rau.RecentPostCount,
    rau.LastActiveDate,
    tu.ReputationRank
FROM TopUsers tu
LEFT JOIN RecentActiveUsers rau ON tu.UserId = rau.UserId
WHERE tu.ReputationRank <= 10
ORDER BY tu.Reputation DESC, rau.RecentPostCount DESC;
