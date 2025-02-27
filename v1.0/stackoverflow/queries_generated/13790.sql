-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(PT.Id) AS PostCount
    FROM Tags T
    LEFT JOIN Posts PT ON T.Id IN (SELECT unnest(string_to_array(PT.Tags, '><')))
    GROUP BY T.Id, T.TagName
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalScore,
    US.AvgViewCount,
    TS.TagId,
    TS.TagName,
    TS.PostCount AS TagPostCount
FROM UserStats US
JOIN TagStats TS ON US.PostCount > 0
ORDER BY US.TotalScore DESC, US.PostCount DESC
LIMIT 100;
