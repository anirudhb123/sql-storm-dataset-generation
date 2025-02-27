-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation, U.CreationDate
),

PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
)

SELECT 
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    U.TotalBounty,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.CommentCount,
    P.VoteCount
FROM UserStats U
JOIN PostStats P ON P.PostId IN (
    SELECT Id FROM Posts WHERE OwnerUserId = U.UserId
)
ORDER BY U.Reputation DESC, P.ViewCount DESC
LIMIT 100;
