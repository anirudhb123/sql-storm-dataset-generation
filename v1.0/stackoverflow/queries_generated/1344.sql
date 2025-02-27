WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        U.Id
), 
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        COALESCE(PC.ClosedDate, 'N/A') AS ClosedStatus,
        (SELECT COUNT(*) FROM Comments WHERE PostId = P.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Posts PC ON P.Id = PC.AcceptedAnswerId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    US.DisplayName,
    US.Reputation,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.CommentCount,
    US.TotalPosts,
    US.TotalComments,
    US.TotalBounties,
    PS.ClosedStatus,
    CASE 
        WHEN US.Reputation > 1000 THEN 'Experienced'
        WHEN US.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Beginner'
    END AS UserCategory
FROM 
    UserStatistics US
JOIN 
    PostDetails PS ON US.UserId = PS.OwnerUserId
WHERE 
    US.TotalPosts > 5
ORDER BY 
    US.Reputation DESC, PS.CommentCount DESC
LIMIT 50;
