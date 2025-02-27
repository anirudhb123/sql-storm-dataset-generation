-- Performance Benchmarking Query
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(V.VoteTypeId = 2) AS UpVoteCount, -- Count of upvotes
        SUM(V.VoteTypeId = 3) AS DownVoteCount -- Count of downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
),
UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(V.BountyAmount) / NULLIF(COUNT(DISTINCT P.Id), 0) AS AvgBountyPerPost
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    PM.PostId,
    PM.PostTypeId,
    PM.CreationDate,
    PM.Score,
    PM.ViewCount,
    PM.CommentCount,
    PM.AnswerCount,
    PM.UpVoteCount,
    PM.DownVoteCount,
    UM.UserId,
    UM.BadgeCount,
    UM.TotalBounty,
    UM.AvgBountyPerPost
FROM 
    PostMetrics PM
JOIN 
    Users U ON PM.OwnerUserId = U.Id
JOIN 
    UserMetrics UM ON UM.UserId = U.Id
ORDER BY 
    PM.Score DESC, PM.ViewCount DESC;
