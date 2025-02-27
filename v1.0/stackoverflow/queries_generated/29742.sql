WITH UserBadges AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName
),
UserPostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM
        Posts P
    GROUP BY
        P.OwnerUserId
),
CombinedStats AS (
    SELECT
        U.UserId,
        U.DisplayName,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(B.GoldBadges, 0) AS GoldBadges,
        COALESCE(B.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.Questions, 0) AS Questions,
        COALESCE(P.Answers, 0) AS Answers,
        COALESCE(P.TotalViews, 0) AS TotalViews,
        COALESCE(P.TotalScore, 0) AS TotalScore
    FROM
        UserBadges B
    FULL OUTER JOIN
        UserPostStats P ON B.UserId = P.OwnerUserId
    FULL OUTER JOIN
        Users U ON COALESCE(B.UserId, P.OwnerUserId) = U.Id
)
SELECT
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    TotalScore,
    RANK() OVER (ORDER BY TotalScore DESC) AS RankByScore,
    RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews
FROM
    CombinedStats
WHERE
    TotalPosts > 0
ORDER BY
    TotalScore DESC,
    TotalViews DESC
LIMIT 100;
