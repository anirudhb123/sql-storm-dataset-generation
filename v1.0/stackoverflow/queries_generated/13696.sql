-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    GROUP BY 
        P.Id, P.PostTypeId, P.Score, P.ViewCount, P.CreationDate
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(U.Reputation) AS TotalReputation,
        AVG(U.Views) AS AvgViews,
        AVG(U.UpVotes) AS AvgUpVotes,
        AVG(U.DownVotes) AS AvgDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PT.Name AS PostType,
    PS.Score,
    PS.ViewCount,
    PS.TotalBounty,
    PS.CommentCount,
    PS.AnswerCount,
    US.UserId,
    US.BadgeCount,
    US.TotalReputation,
    US.AvgViews,
    US.AvgUpVotes,
    US.AvgDownVotes
FROM 
    PostStats PS
JOIN 
    PostTypes PT ON PS.PostTypeId = PT.Id
JOIN 
    Users U ON U.Id = PS.OwnerUserId
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC;
