WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT PH.Id) AS TotalPostHistory
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        TotalBadges,
        TotalPosts,
        TotalComments,
        TotalPostHistory,
        RANK() OVER (ORDER BY Reputation DESC, TotalPosts DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    Rank,
    DisplayName,
    Reputation,
    TotalBounty,
    TotalBadges,
    TotalPosts,
    TotalComments,
    TotalPostHistory
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
