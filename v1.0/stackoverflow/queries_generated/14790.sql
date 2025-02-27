-- Performance benchmarking query to analyze post activity and user interactions

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        COUNT(DISTINCT B.Id) AS BadgesEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.VoteCount,
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.PostsCreated,
    US.BadgesEarned
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostId = U.Id  -- Adjusting the join as needed depending on the association
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount DESC
LIMIT 100;
