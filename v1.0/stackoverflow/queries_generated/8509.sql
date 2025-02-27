WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS AnswerScore,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.PostId) AS TagPostCount
    FROM Tags T
    JOIN Posts PT ON T.Id = PT.Tags::int[]
    GROUP BY T.TagName
    ORDER BY TagPostCount DESC
    LIMIT 10
),
UserReputation AS (
    SELECT 
        UserId,
        SUM(Reputation) AS TotalReputation
    FROM UserStats
    GROUP BY UserId
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        P.ViewCount,
        P.Score
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.AnswerCount,
    US.QuestionScore,
    US.AnswerScore,
    US.BadgeCount,
    PT.TagName,
    UR.TotalReputation,
    RP.Title,
    RP.CreationDate,
    RP.Author,
    RP.ViewCount,
    RP.Score
FROM UserStats US
JOIN PopularTags PT ON true
JOIN UserReputation UR ON US.UserId = UR.UserId
LEFT JOIN RecentPosts RP ON US.UserId = RP.Author
ORDER BY US.Reputation DESC, PT.TagPostCount DESC, RP.CreationDate DESC;
