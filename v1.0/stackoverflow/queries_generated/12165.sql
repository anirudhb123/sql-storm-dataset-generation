-- Performance benchmarking query on the StackOverflow schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        AVG(V.VoteTypeId) AS AverageVoteType
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalScore,
    U.AverageVoteType,
    PT.TagName,
    PT.PostCount
FROM UserStats U
LEFT JOIN PopularTags PT ON PT.PostCount > 0
ORDER BY U.Reputation DESC, U.TotalScore DESC
LIMIT 100;
