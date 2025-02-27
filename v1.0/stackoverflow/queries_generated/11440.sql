-- Performance Benchmarking Query

-- This query gathers statistics from the Posts, Users, Votes, and Comments tables 
-- to evaluate the overall performance of query execution and data retrieval

WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.Id IS NOT NULL) AS TotalVotes,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM
        Users AS U
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes AS V ON P.Id = V.PostId
    LEFT JOIN 
        Comments AS C ON C.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        T.TagName
    FROM 
        Posts AS P
    JOIN 
        Users AS U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Tags AS T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalVotes,
    U.TotalComments,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.LastActivityDate,
    PS.UpVotes,
    PS.DownVotes,
    P.TagName
FROM 
    UserStatistics AS U
JOIN 
    PostStatistics AS P ON U.UserId = P.OwnerDisplayName
LEFT JOIN 
    VoteStatistics AS PS ON P.PostId = PS.PostId
ORDER BY 
    U.TotalPosts DESC, P.Score DESC
LIMIT 100;  -- Limit results for performance testing
