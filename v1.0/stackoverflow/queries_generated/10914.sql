-- Performance Benchmark Query for StackOverflow Schema
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.CreationDate,
        P.LastActivityDate,
        PT.Name AS PostType,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.FavoriteCount, P.CreationDate, P.LastActivityDate, PT.Name
),
TopUsers AS (
    SELECT 
        UserId,
        SUM(Reputation) AS TotalReputation,
        SUM(Views) AS TotalViews,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM UserStats
    GROUP BY UserId
    ORDER BY TotalReputation DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.CreationDate,
    P.LastActivityDate,
    PT.Name AS PostType
FROM TopUsers U
JOIN Posts P ON U.UserId = P.OwnerUserId
JOIN PostTypes PT ON P.PostTypeId = PT.Id
ORDER BY U.TotalReputation DESC, P.CreationDate DESC;
