-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Reputation AS OwnerReputation,
        COUNT(CASE WHEN V.PostId IS NOT NULL THEN 1 END) AS VoteCount,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.FavoriteCount, U.Reputation
),
AggregatedStatistics AS (
    SELECT 
        PostTypeId,
        COUNT(PostId) AS TotalPosts,
        AVG(ViewCount) AS AvgViews,
        AVG(Score) AS AvgScore,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments,
        SUM(VoteCount) AS TotalVotes,
        AVG(OwnerReputation) AS AvgOwnerReputation
    FROM 
        PostStatistics
    GROUP BY 
        PostTypeId
)
SELECT 
    PT.Name AS PostType,
    AS.TotalPosts,
    AS.AvgViews,
    AS.AvgScore,
    AS.TotalAnswers,
    AS.TotalComments,
    AS.TotalVotes,
    AS.AvgOwnerReputation
FROM 
    AggregatedStatistics AS AS
JOIN 
    PostTypes PT ON AS.PostTypeId = PT.Id
ORDER BY 
    AS.TotalPosts DESC;
