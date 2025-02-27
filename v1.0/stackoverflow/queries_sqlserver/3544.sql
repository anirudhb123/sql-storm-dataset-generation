
WITH UserBadges AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
QuestionStats AS (
    SELECT P.OwnerUserId, 
           COUNT(DISTINCT P.Id) AS TotalQuestions, 
           SUM(P.AnswerCount) AS TotalAnswers,
           AVG(P.ViewCount) AS AvgViews,
           MAX(P.CreationDate) AS LastQuestionDate
    FROM Posts P
    WHERE P.PostTypeId = 1
    GROUP BY P.OwnerUserId 
),
PopularTags AS (
    SELECT value AS TagName, COUNT(*) AS TagCount
    FROM Posts T
    CROSS APPLY STRING_SPLIT(T.Tags, '><')
    WHERE T.PostTypeId = 1
    GROUP BY value
    ORDER BY TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
),
UserRanks AS (
    SELECT U.Id, U.DisplayName, U.Reputation,
           RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
)
SELECT U.Id AS UserId, 
       U.DisplayName, 
       COALESCE(UB.GoldBadges, 0) AS GoldBadges,
       COALESCE(UB.SilverBadges, 0) AS SilverBadges,
       COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
       COALESCE(Q.TotalQuestions, 0) AS TotalQuestions,
       COALESCE(Q.TotalAnswers, 0) AS TotalAnswers,
       COALESCE(Q.AvgViews, 0) AS AvgViews,
       U.ReputationRank,
       P.TagName
FROM UserRanks U
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN QuestionStats Q ON U.Id = Q.OwnerUserId
LEFT JOIN PopularTags P ON 1=1
ORDER BY U.ReputationRank, U.DisplayName;
