WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        RANK() OVER (ORDER BY SUM(COALESCE(V.BountyAmount, 0)) DESC) AS BountyRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalBounties,
        TotalPosts,
        TotalComments,
        TotalBadges,
        BountyRank
    FROM 
        UserStatistics
    WHERE 
        BountyRank <= 10
)
SELECT 
    U.DisplayName,
    U.TotalBounties,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    COALESCE((SELECT AVG(V.BountyAmount) 
              FROM Votes V 
              WHERE V.UserId = U.UserId AND V.BountyAmount IS NOT NULL), 0) AS AvgBountyAmount,
    (SELECT COUNT(*) 
     FROM PostHistory PH 
     WHERE PH.UserId = U.UserId 
       AND PH.PostHistoryTypeId IN (10, 11, 12, 13)
    ) AS ClosureActions
FROM 
    TopUsers U
ORDER BY 
    U.TotalBounties DESC;
