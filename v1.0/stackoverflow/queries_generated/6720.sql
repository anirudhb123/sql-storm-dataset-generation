WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    COALESCE(P.PostCount, 0) AS TotalPosts,
    COALESCE(P.QuestionCount, 0) AS TotalQuestions,
    COALESCE(P.AnswerCount, 0) AS TotalAnswers,
    COALESCE(P.TotalScore, 0) AS TotalScore,
    COALESCE(P.TotalViews, 0) AS TotalViews
FROM UserBadgeCounts U
LEFT JOIN PostStatistics P ON U.UserId = P.OwnerUserId
ORDER BY U.Reputation DESC, U.BadgeCount DESC
LIMIT 100;
