-- Performance Benchmarking Query for Stack Overflow Schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS NumberOfPosts,
        COUNT(DISTINCT C.Id) AS NumberOfComments,
        COUNT(DISTINCT B.Id) AS NumberOfBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        PT.Name AS PostType
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.NumberOfPosts,
    U.NumberOfComments,
    U.NumberOfBadges,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.CreationDate,
    P.PostType
FROM UserStats U
JOIN PostStats P ON U.UserId = P.OwnerUserId
ORDER BY U.Reputation DESC, P.Score DESC
LIMIT 100;
