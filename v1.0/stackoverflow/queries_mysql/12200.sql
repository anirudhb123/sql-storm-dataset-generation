
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        PositivePosts,
        NegativePosts,
        AverageViewCount,
        @rank := IF(@prev_reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserReputation, (SELECT @rank := 0, @prev_reputation := NULL) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    PositivePosts,
    NegativePosts,
    AverageViewCount,
    ReputationRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10
ORDER BY 
    ReputationRank;
