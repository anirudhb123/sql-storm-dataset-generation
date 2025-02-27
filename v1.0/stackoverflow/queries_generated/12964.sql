-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
    GROUP BY 
        T.Id, T.TagName
)
SELECT 
    US.UserId,
    US.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalViews,
    US.TotalScore,
    TS.TagId,
    TS.TagName,
    TS.PostCount AS TagPostCount
FROM 
    UserStats US
LEFT JOIN 
    TagStats TS ON TS.PostCount > 0
ORDER BY 
    US.Reputation DESC, US.PostCount DESC;
