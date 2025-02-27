WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.UpVotes IS NOT NULL THEN P.UpVotes ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN P.DownVotes IS NOT NULL THEN P.DownVotes ELSE 0 END) AS TotalDownVotes,
        AVG(P.Score) AS AveragePostScore
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    GROUP BY U.Id
),
CombinedStats AS (
    SELECT 
        T.TagName,
        TS.PostCount AS TotalPostsByTag,
        TS.QuestionCount AS TotalQuestionsByTag,
        TS.AnswerCount AS TotalAnswersByTag,
        TS.TotalViews AS TotalViewsByTag,
        TS.AverageScore AS AvgScoreByTag,
        U.UserId,
        U.DisplayName,
        U.PostCount AS PostsByUser,
        U.QuestionCount AS QuestionsByUser,
        U.AnswerCount AS AnswersByUser,
        U.TotalUpVotes,
        U.TotalDownVotes,
        U.AveragePostScore
    FROM TagStatistics TS
    JOIN UserStatistics U ON U.PostCount > 0 
    ORDER BY TS.TotalViews DESC, U.AveragePostScore DESC
)
SELECT 
    TagName,
    TotalPostsByTag,
    TotalQuestionsByTag,
    TotalAnswersByTag,
    TotalViewsByTag,
    AvgScoreByTag,
    UserId,
    DisplayName,
    PostsByUser,
    QuestionsByUser,
    AnswersByUser,
    TotalUpVotes,
    TotalDownVotes,
    AveragePostScore
FROM CombinedStats
WHERE TotalPostsByTag > 0 AND AvgScoreByTag IS NOT NULL
ORDER BY TotalPostsByTag DESC, TotalViewsByTag DESC;
