
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        @rank := @rank + 1 AS Rank
    FROM UserBadges ub
    JOIN Users u ON ub.UserId = u.Id
    CROSS JOIN (SELECT @rank := 0) r
    ORDER BY Reputation DESC
),
TopPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.OwnerUserId
),
FinalBenchmark AS (
    SELECT 
        tu.UserId,
        tu.Reputation,
        tu.CreationDate,
        tu.LastAccessDate,
        tu.BadgeCount,
        tu.GoldBadges,
        tu.SilverBadges,
        tu.BronzeBadges,
        tp.PostCount,
        tp.TotalScore,
        tp.AvgViewCount
    FROM TopUsers tu
    JOIN TopPosts tp ON tu.UserId = tp.OwnerUserId
    WHERE tu.Rank <= 10
)
SELECT 
    *,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = fb.UserId) AS TotalPostsCreated
FROM FinalBenchmark fb
ORDER BY Reputation DESC;
