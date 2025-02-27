-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
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
        U.Id, U.Reputation
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS HistoryCount
    FROM
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.ViewCount, P.Score
)
SELECT 
    US.UserId,
    US.Reputation,
    US.PostCount,
    US.BadgeCount,
    US.TotalBounty,
    PS.PostId,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.HistoryCount
FROM 
    UserStats US
JOIN 
    PostStats PS ON US.UserId = PS.PostId
ORDER BY 
    US.Reputation DESC, PS.ViewCount DESC
LIMIT 100;
