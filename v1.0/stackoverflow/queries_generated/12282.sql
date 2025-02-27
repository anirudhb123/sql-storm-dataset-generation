-- Performance Benchmark Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(C.ID) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- Only bounty related votes
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(P.Score) AS TotalPostScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.TotalBounty,
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.BadgeCount,
    US.TotalPostScore
FROM 
    PostStats PS
JOIN 
    Users U ON PS.UserId = U.Id
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC;
