WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(*) AS RecentPosts,
        AVG(v.BountyAmount) AS AverageBounty
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.CommentCount,
        us.TotalBounties,
        ra.RecentPosts,
        ra.AverageBounty,
        RANK() OVER (ORDER BY us.TotalBounties DESC, us.PostCount DESC) AS UserRank
    FROM UserStats us
    LEFT JOIN RecentActivity ra ON us.UserId = ra.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.CommentCount,
    COALESCE(tu.RecentPosts, 0) AS RecentPosts,
    COALESCE(tu.AverageBounty, 0) AS AverageBounty,
    COUNT(DISTINCT hp.Id) AS HistoryCount,
    STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
FROM TopUsers tu
LEFT JOIN PostHistory hp ON tu.UserId = hp.UserId 
LEFT JOIN PostHistoryTypes pht ON hp.PostHistoryTypeId = pht.Id
WHERE tu.UserRank <= 10
GROUP BY tu.DisplayName, tu.PostCount, tu.CommentCount, tu.RecentPosts, tu.AverageBounty
ORDER BY tu.UserRank;
