-- Performance Benchmarking Query
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate, U.UpVotes, U.DownVotes
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVoteCount,
        SUM(V.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.CommentCount AS UserCommentCount,
    U.BadgeCount,
    U.TotalBounty,
    P.PostId,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.AnswerCount AS PostAnswerCount,
    P.CommentCount AS PostCommentCount,
    P.UpVoteCount,
    P.DownVoteCount
FROM 
    UserMetrics U
JOIN 
    PostMetrics P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.Score DESC
LIMIT 100;
