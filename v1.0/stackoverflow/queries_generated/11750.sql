-- Performance benchmarking query for Stack Overflow schema
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CreationDate
    FROM Users
),
PostDetails AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate AS PostCreationDate, 
        P.ViewCount, 
        P.Score, 
        P.AnswerCount,
        U.Reputation AS OwnerReputation
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
),
TopPosts AS (
    SELECT 
        P.Title, 
        P.ViewCount, 
        P.Score, 
        P.AnswerCount, 
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (ORDER BY P.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM PostDetails P
    JOIN Users U ON P.OwnerUserId = U.Id
)
SELECT 
    T.Title, 
    T.ViewCount, 
    T.Score, 
    T.AnswerCount, 
    T.OwnerName,
    T.ViewRank,
    T.ScoreRank
FROM TopPosts T
WHERE T.ViewRank <= 10 OR T.ScoreRank <= 10
ORDER BY T.ViewRank, T.ScoreRank;
