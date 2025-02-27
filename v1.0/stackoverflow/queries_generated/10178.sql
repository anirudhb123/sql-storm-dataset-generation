-- Performance Benchmarking Query for StackOverflow Schema
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        P.LastActivityDate,
        P.Tags,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpvotes,
    U.TotalDownvotes,
    P.PostId,
    P.Title,
    P.ViewCount,
    P.Score,
    P.CreationDate,
    P.LastActivityDate,
    P.Tags
FROM 
    UserStatistics U
LEFT JOIN 
    PostDetails P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.TotalPosts DESC, U.TotalUpvotes DESC;
