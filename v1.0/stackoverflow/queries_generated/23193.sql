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
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStatistics
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
            ELSE CAST(QuestionsCount AS FLOAT) / TotalPosts
        END AS QuestionRatio,
        CASE
            WHEN TotalPosts = 0 THEN 0
            ELSE CAST(AnswersCount AS FLOAT) / TotalPosts
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
     AND V.CreationDate >= NOW() - INTERVAL '1 year') AS RecentVoteCount
FROM Users U
JOIN MetricCalculations M ON U.Id = M.UserId
WHERE (M.QuestionRatio > 0.5 OR M.AnswerRatio > 0.5)
  AND (M.GoldBadges + M.SilverBadges + M.BronzeBadges > 0)
ORDER BY M.Reputation DESC, U.DisplayName
FETCH FIRST 10 ROWS ONLY;

### Explanation of the Query:
1. **CTE UserStatistics:** 
   - Calculates statistics for each user, including total posts, counts of questions and answers, and badge counts (gold, silver, bronze).

2. **CTE AggregatedStatistics:** 
   - Computes additional metrics, such as a ranking based on reputation.

3. **CTE MetricCalculations:** 
   - Calculates ratios for questions and answers in relation to total posts while handling division by zero cases.

4. **Main SELECT:**
   - Retrieves user display names and relevant statistics from the previous CTEs.
   - Includes a correlated subquery to count votes made by the user within the last year.
   - Applies filtering logic to ensure users have a decent ratio of questions or answers, and at least one badge.
   - Orders the results by reputation, displaying the top 10 users meeting the criteria.

This query demonstrates various SQL concepts from the requirements, including CTEs, correlated subqueries, window functions, complex predicates, and NULL logic handling.
