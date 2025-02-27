-- Performance benchmarking query for the StackOverflow schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        C.CloseReason AS CloseReason,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, C.CloseReason
),
TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        UserStats
    ORDER BY 
        Reputation DESC
    LIMIT 10
)

SELECT 
    U.DisplayName, 
    U.Reputation, 
    U.PostCount, 
    U.CommentCount, 
    U.UpVotes, 
    U.DownVotes, 
    P.Title, 
    P.CreationDate, 
    P.Score, 
    P.ViewCount, 
    P.AnswerCount, 
    P.CommentCount
FROM 
    TopUsers U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.Score DESC;
