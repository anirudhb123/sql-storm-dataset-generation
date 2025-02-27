-- Performance Benchmark Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
)
SELECT 
    US.UserId,
    US.Reputation,
    US.CreationDate,
    US.PostCount,
    US.BadgeCount,
    US.TotalViews,
    US.TotalScore,
    PS.PostId,
    PS.PostTypeId,
    PS.CreationDate AS PostCreationDate,
    PS.Score AS PostScore,
    PS.ViewCount AS PostViewCount,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes
FROM 
    UserStats US
JOIN 
    PostStats PS ON PS.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = US.UserId)
ORDER BY 
    US.Reputation DESC, PS.Score DESC;
