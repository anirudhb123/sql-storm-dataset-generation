WITH RECURSIVE UserPostCounts AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
), PostScores AS (
    SELECT
        p.Id AS PostId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
), TopUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(upc.PostCount, 0) AS TotalPosts,
        SUM(ps.Score) AS TotalScore
    FROM Users u
    LEFT JOIN UserPostCounts upc ON u.Id = upc.UserId
    LEFT JOIN PostScores ps ON u.Id = ps.OwnerUserId
    GROUP BY u.Id
    HAVING COUNT(ps.PostId) > 5
), HighReputationUsers AS (
    SELECT
        Id,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalScore
    FROM TopUsers
    WHERE Reputation > (
        SELECT AVG(Reputation) FROM Users
    )
), RecentTopPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName
    FROM Posts p
    INNER JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'
    ORDER BY p.CreationDate DESC
), UserComments AS (
    SELECT
        c.UserId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.UserId
)
SELECT
    u.DisplayName,
    u.Reputation,
    hu.TotalPosts,
    hu.TotalScore,
    COALESCE(uc.CommentCount, 0) AS TotalComments,
    ARRAY_AGG(rtp.Title) AS RecentTopPostTitles
FROM HighReputationUsers hu
JOIN Users u ON u.Id = hu.Id
LEFT JOIN UserComments uc ON u.Id = uc.UserId
LEFT JOIN RecentTopPosts rtp ON u.Id = rtp.OwnerUserId
GROUP BY u.Id, hu.TotalPosts, hu.TotalScore
ORDER BY hu.TotalScore DESC, u.Reputation DESC
LIMIT 10;
