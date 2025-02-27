WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        pb.PostCount,
        ub.BadgeCount,
        pb.TotalScore,
        pb.AvgViewCount,
        RANK() OVER (ORDER BY pb.TotalScore DESC, ub.BadgeCount DESC) AS UserRank
    FROM UserBadges ub
    JOIN PostStats pb ON ub.UserId = pb.OwnerUserId
)
SELECT 
    tu.DisplayName,
    COALESCE(tu.PostCount, 0) AS PostCount,
    COALESCE(tu.BadgeCount, 0) AS BadgeCount,
    COALESCE(tu.TotalScore, 0) AS TotalScore,
    COALESCE(tu.AvgViewCount, 0) AS AvgViewCount,
    CASE 
        WHEN tu.UserRank IS NULL THEN 'Unranked'
        ELSE CAST(tu.UserRank AS VARCHAR)
    END AS RankStatus
FROM TopUsers tu
LEFT JOIN Users u ON tu.UserId = u.Id
WHERE (u.Reputation > 1000 OR tu.BadgeCount > 5)
    AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
ORDER BY tu.UserRank ASC NULLS LAST
FETCH FIRST 50 ROWS ONLY
UNION ALL
SELECT 
    'Anonymous User' AS DisplayName,
    0 AS PostCount,
    0 AS BadgeCount,
    0 AS TotalScore,
    0 AS AvgViewCount,
    'No Rank' AS RankStatus
ORDER BY RankStatus;
