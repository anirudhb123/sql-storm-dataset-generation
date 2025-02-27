-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBountyAmount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN 
        Comments C ON U.Id = C.UserId 
    LEFT JOIN 
        Badges B ON U.Id = B.UserId 
    LEFT JOIN 
        Votes V ON U.Id = V.UserId 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,
        SUM(V.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.TotalBadges,
    US.TotalBountyAmount,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.TotalComments AS PostTotalComments,
    PS.TotalUpVotes,
    PS.TotalDownVotes
FROM 
    UserStats US
JOIN 
    PostStats PS ON US.UserId = PS.OwnerUserId
ORDER BY 
    US.Reputation DESC, 
    PS.Score DESC;
