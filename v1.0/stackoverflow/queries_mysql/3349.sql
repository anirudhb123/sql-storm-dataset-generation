
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
PostAnalytics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(PH.Comment, 'No history') AS LastActionComment,
        @rn := IF(@prev_owner = P.OwnerUserId, @rn + 1, 1) AS rn,
        @prev_owner := P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    CROSS JOIN (SELECT @rn := 0, @prev_owner := NULL) AS vars
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopUsers AS (
    SELECT 
        UserId, 
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank 
    FROM 
        UserReputation 
    WHERE 
        TotalPosts > 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    PA.Title,
    PA.CreationDate,
    PA.ViewCount,
    PA.Score,
    PA.LastActionComment,
    T.UserRank
FROM 
    UserReputation U
JOIN 
    PostAnalytics PA ON U.UserId = PA.OwnerUserId
JOIN 
    TopUsers T ON U.UserId = T.UserId
WHERE 
    PA.rn = 1
ORDER BY 
    U.Reputation DESC, PA.Score DESC
LIMIT 15;
