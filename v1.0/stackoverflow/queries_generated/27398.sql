WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(V.Score) AS AvgVoteScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),

TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
),

RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserDisplayName,
        PH.CreationDate,
        P.Title,
        P.Body,
        P.Tags,
        P.Score,
        P.ViewCount,
        P.LastActivityDate,
        P.AcceptedAnswerId,
        PH.PostHistoryTypeId,
        P.OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentEditRank
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (4, 5, 6, 10, 11)
)

SELECT 
    UR.DisplayName AS UserName,
    UR.PostCount,
    UR.QuestionCount,
    UR.AnswerCount,
    UR.AvgVoteScore AS UserAvgVoteScore,
    TS.TagName,
    TS.PostCount AS TagPostCount,
    TS.QuestionCount AS TagQuestionCount,
    TS.AnswerCount AS TagAnswerCount,
    RPH.Title,
    RPH.Body,
    RPH.CreationDate AS RecentEditDate,
    RPH.UserDisplayName AS EditedBy,
    RPH.Score,
    RPH.ViewCount,
    RPH.LastActivityDate
FROM UserReputation UR
JOIN TagStatistics TS ON UR.PostCount > 50 -- User with a significant number of posts
JOIN RecentPostHistory RPH ON RPH.RecentEditRank = 1
WHERE UR.Reputation > 1000 -- Filter for reputable users
ORDER BY UR.Reputation DESC, TS.PostCount DESC, RPH.Score DESC
LIMIT 100;
