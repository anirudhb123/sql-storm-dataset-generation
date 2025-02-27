-- Performance Benchmarking Query
-- This query retrieves various statistics related to posts, users, and votes to assess system performance.

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, U.Reputation
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT B.Id) AS BadgesCount,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerReputation,
    PS.TotalComments,
    PS.TotalVotes,
    US.UserId,
    US.Reputation AS UserReputation,
    US.PostsCount,
    US.BadgesCount,
    US.TotalAnswers
FROM 
    PostStats PS
JOIN 
    Users U ON PS.OwnerUserId = U.Id
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;  -- Limiting results for performance reasons
