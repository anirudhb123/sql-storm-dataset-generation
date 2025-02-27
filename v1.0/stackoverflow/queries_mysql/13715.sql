
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.Reputation, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        @rank := IF(@prev_reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserReputation, (SELECT @rank := 0, @prev_reputation := NULL) AS vars
    ORDER BY 
        Reputation DESC
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    CommentCount,
    ReputationRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10
ORDER BY 
    ReputationRank;
