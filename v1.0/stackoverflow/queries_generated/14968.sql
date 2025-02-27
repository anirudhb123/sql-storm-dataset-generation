-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId 
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty
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
    PS.PostId,
    PS.PostTypeId,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    US.UserId,
    US.Reputation,
    US.BadgeCount,
    US.TotalBounty
FROM 
    PostStats PS
JOIN 
    Users US ON PS.PostTypeId = 1  -- Assuming PostTypeId = 1 is for Questions
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;
