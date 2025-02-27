-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(A.Id) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  -- BountyStart
    GROUP BY 
        P.Id
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.TotalComments,
    PS.TotalAnswers,
    PS.TotalBounties,
    US.UserId,
    US.DisplayName AS UserDisplayName,
    US.TotalBadges,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.AvgReputation
FROM 
    PostStats PS
JOIN 
    Users U ON PS.UserId = U.Id   -- Assuming you want to link user stats as well
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.CreationDate DESC
LIMIT 1000;  -- Limiting to 1000 for performance
