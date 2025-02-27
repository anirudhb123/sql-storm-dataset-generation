-- Performance Benchmarking SQL Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(V.Score, 0)) AS TotalVoteScore,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.Reputation
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
        P.FavoriteCount,
        PT.Name AS PostType,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, PT.Name
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.TotalVoteScore,
    U.TotalCommentScore,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.PostType,
    P.VoteCount
FROM UserStats U
JOIN PostStats P ON U.UserId = P.OwnerUserId
ORDER BY U.Reputation DESC, P.ViewCount DESC;
