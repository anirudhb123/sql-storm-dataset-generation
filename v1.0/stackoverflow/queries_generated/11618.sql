-- Performance Benchmarking Query for StackOverflow Schema
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.LastActivityDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    GROUP BY 
        P.Id, P.PostTypeId, P.Score, P.ViewCount, P.CreationDate, P.LastActivityDate
),
UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    PM.PostId,
    PM.PostTypeId,
    PM.Score,
    PM.ViewCount,
    PM.CreationDate,
    PM.LastActivityDate,
    PM.CommentCount,
    PM.AnswerCount,
    UM.UserId,
    UM.Reputation,
    UM.BadgeCount,
    UM.TotalBounties
FROM 
    PostMetrics PM
JOIN 
    Users UM ON PM.PostTypeId = 1 AND PM.CreationDate >= U.CreationDate
ORDER BY 
    PM.LastActivityDate DESC;
