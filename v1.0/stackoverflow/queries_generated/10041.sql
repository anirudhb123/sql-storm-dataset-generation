-- Performance benchmarking query for StackOverflow schema
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,
        SUM(V.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
)

SELECT 
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.PostId,
    P.PostTypeId,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.TotalComments AS PostTotalComments,
    P.TotalVotes AS PostTotalVotes
FROM 
    UserStats U
JOIN 
    PostStats P ON P.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.UserId)
ORDER BY 
    U.Reputation DESC, P.Score DESC;
