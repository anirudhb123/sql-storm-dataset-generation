
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalBounty,
        @rank := IF(@prev_rank = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_rank := Reputation
    FROM 
        UserStatistics, (SELECT @rank := 0, @prev_rank := NULL) AS r
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId, 
    DisplayName,
    Reputation,
    TotalPosts,
    TotalComments,
    TotalBounty,
    ReputationRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10
ORDER BY 
    Reputation DESC;
