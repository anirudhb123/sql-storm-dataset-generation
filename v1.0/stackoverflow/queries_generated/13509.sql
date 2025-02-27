-- Performance Benchmarking SQL Query
-- The below query retrieves user statistics and post engagement over time

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.CreationDate IS NOT NULL) AS TotalVotes 
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.TotalBadges,
    US.TotalVotes,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount
FROM 
    UserStats US
JOIN 
    PostStats PS ON US.UserId = PS.OwnerDisplayName
ORDER BY 
    US.Reputation DESC, PS.Score DESC; 
