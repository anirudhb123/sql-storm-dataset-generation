-- Performance Benchmarking Query for Stack Overflow Schema

WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)

SELECT 
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalQuestions,
    U.TotalAnswers,
    P.PostId,
    P.Title,
    P.ViewCount,
    P.Score,
    P.CreationDate,
    P.UpVotes,
    P.DownVotes
FROM 
    UserStatistics U
JOIN 
    PostStatistics P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC
LIMIT 100;  -- Limiting the results for benchmarking
