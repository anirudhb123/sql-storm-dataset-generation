WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScores,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScores
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
        TotalPosts,
        PositiveScores,
        NegativeScores,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(T.Id) AS TagCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(T.Id) > 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.PositiveScores,
    U.NegativeScores,
    T.TagName,
    T.TagCount
FROM 
    TopUsers U
LEFT JOIN 
    PopularTags T ON U.PositiveScores > 5 AND RANK() OVER (PARTITION BY T.TagName ORDER BY U.Reputation DESC) <= 5
ORDER BY 
    U.ReputationRank, T.TagCount DESC
LIMIT 50;
