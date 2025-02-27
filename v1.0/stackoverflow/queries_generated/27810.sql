WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(P.Score, 0)) AS TotalPostScore,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PostMetrics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.ViewCount) AS AvgViews,
        AVG(P.Score) AS AvgScore,
        AVG(P.AnswerCount) AS AvgAnswers,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
    FROM 
        Posts P
    LEFT JOIN 
        UNNEST(string_to_array(P.Tags, '><')) AS T(TagName) ON TRUE
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),

FinalBenchmark AS (
    SELECT 
        U.DisplayName,
        U.TotalPosts,
        U.TotalComments,
        U.TotalPostScore,
        U.TotalBadges,
        U.TotalVotes,
        PM.PostCount,
        PM.AvgViews,
        PM.AvgScore,
        PM.AvgAnswers,
        PM.TagsUsed
    FROM 
        UserActivity U
    LEFT JOIN 
        PostMetrics PM ON U.UserId = PM.OwnerUserId
)

SELECT 
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalPostScore,
    TotalBadges,
    TotalVotes,
    COALESCE(PostCount, 0) AS PostCount,
    COALESCE(AvgViews, 0) AS AvgViews,
    COALESCE(AvgScore, 0) AS AvgScore,
    COALESCE(AvgAnswers, 0) AS AvgAnswers,
    COALESCE(TagsUsed, 'None') AS TagsUsed
FROM 
    FinalBenchmark
ORDER BY 
    TotalPostScore DESC, 
    TotalVotes DESC
LIMIT 20;
