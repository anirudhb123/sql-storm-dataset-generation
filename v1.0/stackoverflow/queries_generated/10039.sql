-- Performance benchmarking query for the StackOverflow schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation, U.CreationDate, U.DisplayName, U.UpVotes, U.DownVotes
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
        PT.Name AS PostType
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
),
VoteStats AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Votes V
    GROUP BY V.PostId
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    PS.PostId,
    PS.Title,
    PS.CreationDate AS PostCreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    VS.UpVoteCount,
    VS.DownVoteCount,
    US.BadgeCount,
    US.PostCount,
    US.CommentCount
FROM UserStats US
JOIN PostStats PS ON US.UserId = PS.OwnerUserId
LEFT JOIN VoteStats VS ON PS.PostId = VS.PostId
ORDER BY US.Reputation DESC, PS.Score DESC;
