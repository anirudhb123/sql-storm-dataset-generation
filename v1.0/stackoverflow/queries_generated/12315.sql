-- Performance Benchmark Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.VoteTypeId = 2) AS UpVotes, -- Assuming VoteTypeId = 2 is UpMod
        SUM(V.VoteTypeId = 3) AS DownVotes -- Assuming VoteTypeId = 3 is DownMod
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        C.CommentCount, 
        COALESCE(C.CommentCount, 0) AS TotalComments,
        COALESCE(H.HistoryCount, 0) AS RevisionCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS HistoryCount
        FROM 
            PostHistory 
        GROUP BY 
            PostId
    ) H ON P.Id = H.PostId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.UpVotes,
    U.DownVotes,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.TotalComments,
    P.RevisionCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.PostId; -- Join in a meaningful way based on user and post association
