-- Performance benchmarking query to assess the data distribution and relationship in the StackOverflow schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.LastActivityDate,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Score, P.ViewCount, P.CreationDate, P.LastActivityDate
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCreated
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
    ORDER BY PostsCreated DESC
    LIMIT 10
)

SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.BadgeCount,
    P.PostId,
    P.Score,
    P.ViewCount,
    P.CreationDate,
    P.LastActivityDate,
    P.CommentCount AS PostCommentCount,
    P.VoteCount,
    M.DisplayName AS MostActiveUser,
    M.PostsCreated
FROM UserStats U
JOIN PostStats P ON U.UserId = P.PostId
LEFT JOIN MostActiveUsers M ON U.UserId = M.UserId
ORDER BY U.Reputation DESC, P.Score DESC;
