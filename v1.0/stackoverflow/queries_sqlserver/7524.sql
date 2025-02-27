
WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount, 
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ISNULL(UB.BadgeCount, 0) AS BadgeCount,
        ISNULL(UB.GoldBadges, 0) AS GoldBadges,
        ISNULL(UB.SilverBadges, 0) AS SilverBadges,
        ISNULL(UB.BronzeBadges, 0) AS BronzeBadges,
        ISNULL(PS.TotalPosts, 0) AS TotalPosts,
        ISNULL(PS.Questions, 0) AS Questions,
        ISNULL(PS.Answers, 0) AS Answers,
        ISNULL(PS.TotalViews, 0) AS TotalViews,
        ISNULL(PS.TotalScore, 0) AS TotalScore
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    WHERE U.LastAccessDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    TotalScore
FROM ActiveUsers
ORDER BY TotalScore DESC, Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
