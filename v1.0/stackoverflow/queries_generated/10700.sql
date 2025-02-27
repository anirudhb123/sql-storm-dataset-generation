-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId 
        AND A.PostTypeId = 2
    WHERE 
        P.CreationDate >= '2023-01-01' -- Filter for posts created in the current year
    GROUP BY 
        P.Id
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.CreationDate >= '2023-01-01' -- Filter for users created in the current year
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.BadgeCount,
    US.VoteCount
FROM 
    PostStats PS
JOIN 
    Users US ON PS.PostId = US.Id
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount DESC;
