-- Performance benchmarking query for Stack Overflow schema
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
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
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
)
SELECT 
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpvotes,
    U.TotalDownvotes,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.TotalComments AS PostTotalComments,
    P.TotalVotes,
    P.Upvotes,
    P.Downvotes
FROM 
    UserReputation U
JOIN 
    PostStatistics P ON P.PostId IN (
        SELECT Id FROM Posts WHERE OwnerUserId = U.UserId
    )
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC
LIMIT 100;  -- Limit to top 100 for benchmarking purposes
