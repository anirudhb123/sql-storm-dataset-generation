WITH UserBadges AS (
    SELECT U.Id AS UserId, COUNT(B.Id) AS BadgeCount, SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount, SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS PostCount, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(P.ViewCount) AS TotalViews, SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT U.Id AS UserId, U.DisplayName, U.Reputation, U.Badges, 
           COALESCE(ABS(SUM(EXTRACT(EPOCH FROM (P.LastActivityDate - U.LastAccessDate))), 0)) AS LastActiveDuration,
           COALESCE(SUM(BadgeCount), 0) AS TotalBadges,
           COALESCE(SUM(PostCount), 0) AS TotalPosts,
           COALESCE(SUM(QuestionCount), 0) AS TotalQuestions,
           COALESCE(SUM(AnswerCount), 0) AS TotalAnswers,
           COALESCE(SUM(TotalViews), 0) AS TotalPostViews,
           COALESCE(SUM(TotalScore), 0) AS TotalPostScore,
           COALESCE(GoldCount, 0) AS GoldBadges, COALESCE(SilverCount, 0) AS SilverBadges, COALESCE(BronzeCount, 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Badges, GoldCount, SilverCount, BronzeCount
)
SELECT UserId, DisplayName, Reputation, TotalBadges, TotalPosts, TotalQuestions, TotalAnswers,
       TotalPostViews, TotalPostScore, GoldBadges, SilverBadges, BronzeBadges,
       LastActiveDuration 
FROM UserActivity
ORDER BY Reputation DESC, TotalPosts DESC
LIMIT 100;
