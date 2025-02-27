-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.TotalBounty,
    P.PostId,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.CommentCount AS PostCommentCount,
    P.UpVoteCount,
    P.DownVoteCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC;
