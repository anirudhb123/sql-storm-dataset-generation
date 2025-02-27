-- Performance benchmarking query to retrieve user statistics and post metrics

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TotalPostsWithTag
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, ','))
    GROUP BY 
        T.TagName
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.CreationDate,
    US.LastAccessDate,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalScore,
    US.TotalViews,
    TS.TagName,
    TS.TotalPostsWithTag
FROM 
    UserStats US
LEFT JOIN 
    TagStats TS ON TS.TotalPostsWithTag > 0
ORDER BY 
    US.Reputation DESC, 
    US.TotalScore DESC;
