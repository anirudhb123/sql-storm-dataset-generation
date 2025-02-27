
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
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
    WHERE p.CreationDate >= CAST(DATE_SUB('2024-10-01', INTERVAL 1 YEAR) AS DATE)
    GROUP BY p.OwnerUserId
),
AggregatedStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AvgViewCount, 0) AS AvgViewCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        @ranking := @ranking + 1 AS Ranking
    FROM UserBadges ub
    LEFT JOIN PostStats ps ON ub.UserId = ps.OwnerUserId,
    (SELECT @ranking := 0) r
    ORDER BY COALESCE(ps.TotalScore, 0) DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    AvgViewCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Ranking
FROM AggregatedStats
WHERE UserId IS NOT NULL
ORDER BY Ranking, DisplayName;
