
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
AggregatedStatistics AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        QuestionsCount,
        AnswersCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        @row_num := @row_num + 1 AS ReputationRank
    FROM UserStatistics, (SELECT @row_num := 0) AS rn
    ORDER BY Reputation DESC
),
MetricCalculations AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        QuestionsCount,
        AnswersCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        CASE
            WHEN TotalPosts = 0 THEN 0
            ELSE CAST(QuestionsCount AS DECIMAL) / TotalPosts
        END AS QuestionRatio,
        CASE
            WHEN TotalPosts = 0 THEN 0
            ELSE CAST(AnswersCount AS DECIMAL) / TotalPosts
        END AS AnswerRatio
    FROM AggregatedStatistics
)
SELECT 
    U.DisplayName,
    U.Id,
    U.Reputation,
    M.TotalPosts,
    M.QuestionsCount,
    M.AnswersCount,
    M.GoldBadges,
    M.SilverBadges,
    M.BronzeBadges,
    M.QuestionRatio,
    M.AnswerRatio,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.UserId = U.Id 
     AND V.CreationDate >= NOW() - INTERVAL 1 YEAR) AS RecentVoteCount
FROM Users U
JOIN MetricCalculations M ON U.Id = M.UserId
WHERE (M.QuestionRatio > 0.5 OR M.AnswerRatio > 0.5)
  AND (M.GoldBadges + M.SilverBadges + M.BronzeBadges > 0)
ORDER BY M.Reputation DESC, U.DisplayName
LIMIT 10;
