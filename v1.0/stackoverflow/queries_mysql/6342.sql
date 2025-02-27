
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount END), 0) AS AnsweredQuestions,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 5 THEN 1 END), 0) AS TagWikiCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId IN (3, 4) THEN 1 END), 0) AS WikiCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
),
UserActivity AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.PostCount,
        U.AnsweredQuestions,
        U.AnswerCount,
        U.TagWikiCount,
        U.WikiCount,
        COALESCE(BC.BadgeCount, 0) AS BadgeCount
    FROM UserStats U
    LEFT JOIN BadgeCounts BC ON U.UserId = BC.UserId
),
RankedUsers AS (
    SELECT 
        UA.*,
        @rank := IF(@prevReputation = UA.Reputation AND @prevPostCount = UA.PostCount, @rank, @rank + 1) AS UserRank,
        @prevReputation := UA.Reputation,
        @prevPostCount := UA.PostCount
    FROM UserActivity UA, (SELECT @rank := 0, @prevReputation := NULL, @prevPostCount := NULL) r
    ORDER BY UA.Reputation DESC, UA.PostCount DESC
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    RU.PostCount,
    RU.AnsweredQuestions,
    RU.AnswerCount,
    RU.TagWikiCount,
    RU.WikiCount,
    RU.BadgeCount,
    RU.UserRank
FROM RankedUsers RU
WHERE RU.UserRank <= 10
ORDER BY RU.Reputation DESC, RU.PostCount DESC;
