
WITH UserPostCounts AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        CommentCount,
        @rank := IF(@prev_reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserPostCounts, (SELECT @rank := 0, @prev_reputation := NULL) AS vars
    ORDER BY 
        Reputation DESC
)

SELECT 
    UserId,
    Reputation,
    PostCount,
    CommentCount,
    ReputationRank
FROM 
    RankedUsers
WHERE 
    ReputationRank <= 10 
ORDER BY 
    Reputation DESC;
