-- Performance benchmarking query for StackOverflow schema
WITH UserStatistics AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        MAX(V.CreationDate) AS LastVoteDate
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount
)
SELECT 
    US.UserId,
    US.Reputation,
    US.Views,
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    US.PostCount,
    US.CommentCount,
    US.BadgeCount,
    PS.LastVoteDate
FROM 
    UserStatistics US
JOIN 
    PostStatistics PS ON US.UserId = PS.PostId
ORDER BY 
    US.Reputation DESC, PS.ViewCount DESC
LIMIT 100;
