-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    LEFT JOIN Votes V ON V.UserId = U.Id
    GROUP BY U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.CreationDate,
        PT.Name AS PostType
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
),
CommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM Comments
    GROUP BY PostId
)
SELECT
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.UpVotes,
    U.DownVotes,
    P.PostId,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    COALESCE(C.CommentCount, 0) AS CommentCount,
    P.FavoriteCount,
    P.CreationDate,
    P.PostType
FROM UserStats U
JOIN PostStats P ON U.UserId = P.OwnerUserId
LEFT JOIN CommentStats C ON P.PostId = C.PostId
ORDER BY U.Reputation DESC, P.CreationDate DESC
LIMIT 100; -- Limit to top 100 results for performance
