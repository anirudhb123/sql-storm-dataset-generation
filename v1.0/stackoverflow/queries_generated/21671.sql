WITH UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
), 
PostStatisticsCTE AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
), 
CombinedStats AS (
    SELECT 
        U.DisplayName,
        COALESCE(UR.Reputation, 0) AS Reputation,
        COALESCE(UR.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore
    FROM Users U
    LEFT JOIN UserReputationCTE UR ON U.Id = UR.UserId
    LEFT JOIN PostStatisticsCTE PS ON U.Id = PS.OwnerUserId
    WHERE U.Reputation IS NOT NULL
), 
RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalScore DESC, Reputation DESC) AS ScoreRank
    FROM CombinedStats
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalScore,
    R.ScoreRank,
    COALESCE(Tags.TagName, 'No Tag') AS MostPopularTag,
    CASE 
        WHEN U.AnswerCount > (SELECT AVG(AnswerCount) FROM PostStatisticsCTE) THEN 'Above Average'
        ELSE 'Below Average'
    END AS AnswerCountLevel,
    (SELECT STRING_AGG(DISTINCT TA.TagName, ', ') 
     FROM Posts P
     JOIN Tags TA ON P.Tags LIKE '%' || TA.TagName || '%'
     WHERE P.OwnerUserId = U.Id) AS AllTagsUsed
FROM RankedUsers U
LEFT JOIN (SELECT 
               P.OwnerUserId, 
               P.Tags 
           FROM Posts P 
           GROUP BY P.OwnerUserId, P.Tags 
           ORDER BY COUNT(P.Id) DESC 
           LIMIT 1) AS MostPopularTag ON U.UserId = MostPopularTag.OwnerUserId
ORDER BY R.ScoreRank;

-- Note: The usage of COALESCE and STRING_AGG functions, along with 
-- window functions to rank users based on their activity and a descriptive 
-- CASE statement for user levels, create a comprehensive summary 
-- of user engagement reflecting SQL's sophisticated capabilities.
