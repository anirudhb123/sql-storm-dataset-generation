
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalBounties,
        @row_number := @row_number + 1 AS ReputationRank
    FROM 
        UserReputation, (SELECT @row_number := 0) AS r
    ORDER BY 
        Reputation DESC
)
SELECT 
    U.DisplayName,
    T.Reputation,
    T.TotalPosts,
    T.TotalComments,
    T.TotalBounties
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
WHERE 
    T.ReputationRank <= 10;
