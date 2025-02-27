-- Performance Benchmarking Query

WITH PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.CommentCount,
        PS.AnswerCount,
        UR.Reputation,
        UR.BadgeCount
    FROM 
        PostSummary PS
    JOIN 
        Users U ON PS.PostId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL) -- Posts with owners
    JOIN 
        UserReputation UR ON U.Id = UR.UserId
)

SELECT 
    PD.*,
    CAST(PD.CreationDate AS DATE) AS PostDate,
    NOW() - PD.CreationDate AS TimeSinceCreation
FROM 
    PostDetails PD
ORDER BY 
    PD.ViewCount DESC
LIMIT 100;
