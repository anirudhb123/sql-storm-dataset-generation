
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
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
        @rank := IF(@prev_reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserReputation, (SELECT @rank := 0, @prev_reputation := NULL) AS vars
    ORDER BY 
        Reputation DESC
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.BadgeNames, 'No Badges') AS Badges,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    U.TotalPosts,
    U.TotalComments
FROM 
    TopUsers U
LEFT JOIN 
    (SELECT 
        B.UserId,
        GROUP_CONCAT(B.Name SEPARATOR ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId) UB ON U.UserId = UB.UserId
WHERE 
    U.ReputationRank <= 10
ORDER BY 
    U.Reputation DESC
LIMIT 10;
