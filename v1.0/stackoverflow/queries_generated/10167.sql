-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
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
        P.CreationDate >= '2022-01-01'  -- filter posts created in the year 2022 onwards
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
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
    UR.Reputation AS UserReputation,
    UR.BadgeCount
FROM 
    PostStats PS
JOIN 
    Users U ON PS.OwnerUserId = U.Id -- assuming we are interested in Post Owners
JOIN 
    UserReputation UR ON U.Id = UR.UserId
ORDER BY 
    PS.CreationDate DESC;
