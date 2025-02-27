
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    ISNULL(U.TotalPosts, 0) AS TotalPosts,
    ISNULL(U.TotalQuestions, 0) AS TotalQuestions,
    ISNULL(U.TotalAnswers, 0) AS TotalAnswers,
    ISNULL(U.TotalScore, 0) AS TotalScore,
    ISNULL(U.AvgViewCount, 0) AS AvgViewCount,
    ISNULL(B.TotalBadges, 0) AS TotalBadges,
    ISNULL(B.GoldBadges, 0) AS GoldBadges,
    ISNULL(B.SilverBadges, 0) AS SilverBadges,
    ISNULL(B.BronzeBadges, 0) AS BronzeBadges,
    U.LastPostDate
FROM UserPostStats U
LEFT JOIN UserBadgeStats B ON U.UserId = B.UserId
ORDER BY U.TotalPosts DESC;
