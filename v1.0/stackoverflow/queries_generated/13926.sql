-- Performance Benchmarking SQL Query

WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C) AS CommentCount,
        COUNT(V) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(V) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.TotalViewCount,
    U.TotalScore,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes
FROM 
    UserReputation U
JOIN 
    PostStatistics PS ON U.UserId = PS.PostId
ORDER BY 
    U.Reputation DESC, PS.Score DESC;
