
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.PostTypeId,
        DATEDIFF(SECOND, P.CreationDate, '2024-10-01 12:34:56') AS AgeInSeconds,
        P.OwnerUserId
    FROM Posts P
)

SELECT
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.PostTypeId,
    P.AgeInSeconds
FROM UserStats U
JOIN PostStats P ON U.UserId = P.OwnerUserId
ORDER BY U.Reputation DESC, P.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
