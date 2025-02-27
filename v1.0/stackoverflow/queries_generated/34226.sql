WITH RECURSIVE UserReputationCTE AS (
    SELECT U.Id, U.Reputation, 
           (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount
    FROM Users U
    WHERE U.Reputation IS NOT NULL
    UNION ALL
    SELECT U.Id, U.Reputation + 50, 
           (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) 
    FROM Users U
    JOIN UserReputationCTE CTE ON U.Id = CTE.Id
    WHERE CTE.Reputation < 1000
),
UserBadges AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
HighRepUsers AS (
    SELECT U.Id, U.DisplayName, 
           COALESCE(B.GoldBadges, 0) AS GoldBadges,
           COALESCE(B.SilverBadges, 0) AS SilverBadges,
           COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
           U.Reputation, R.PostCount
    FROM Users U
    LEFT JOIN UserBadges B ON U.Id = B.UserId
    LEFT JOIN UserReputationCTE R ON U.Id = R.Id
    WHERE U.Reputation >= 500
),
PostInsights AS (
    SELECT P.OwnerUserId, 
           COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
           COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
           SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
FinalResults AS (
    SELECT H.Id, H.DisplayName,
           H.GoldBadges, H.SilverBadges, H.BronzeBadges,
           P.Questions, P.Answers, P.TotalScore
    FROM HighRepUsers H
    LEFT JOIN PostInsights P ON H.Id = P.OwnerUserId
)
SELECT Id, DisplayName,
       CONCAT('Gold: ', GoldBadges, ', Silver: ', SilverBadges, ', Bronze: ', BronzeBadges) AS BadgeSummary,
       COALESCE(Questions, 0) AS QuestionsCount,
       COALESCE(Answers, 0) AS AnswersCount,
       COALESCE(TotalScore, 0) AS UserScore
FROM FinalResults
ORDER BY UserScore DESC, DisplayName ASC
LIMIT 10;
