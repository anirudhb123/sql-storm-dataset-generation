-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        GREATEST(0, (COALESCE(SUM(V.VoteTypeId = 2), 0) - COALESCE(SUM(V.VoteTypeId = 3), 0))) AS NetVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.AnswerCount,
    U.QuestionCount,
    U.CommentCount,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.UpVotes,
    P.DownVotes,
    P.NetVotes
FROM 
    UserStats U
JOIN 
    PostDetails P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.Score DESC
LIMIT 100;
