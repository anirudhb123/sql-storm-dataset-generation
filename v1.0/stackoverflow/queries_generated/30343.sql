WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        1 AS Level 
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        UR.Level + 1
    FROM 
        Users U
    INNER JOIN 
        UserReputation UR ON UR.Reputation < U.Reputation
),

PostRanks AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),

PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)

SELECT 
    U.DisplayName,
    COALESCE(UR.Level, 0) AS ReputationLevel,
    PS.TotalPosts,
    PS.TotalScore,
    PS.AverageScore
FROM 
    Users U
LEFT JOIN 
    UserReputation UR ON U.Id = UR.Id
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
WHERE 
    (PS.TotalPosts > 10 OR PS.TotalPosts IS NULL)
ORDER BY 
    U.Reputation DESC, PS.TotalScore DESC;

-- Furthermore, fetching posts with highest votes and their respective tag counts
SELECT 
    P.Title,
    P.Score,
    (SELECT COUNT(T.Id) FROM Tags T WHERE T.Id IN (
        SELECT unnest(string_to_array(P.Tags, '><'))::int
    )) AS TagCount
FROM 
    Posts P
WHERE 
    P.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    P.Score DESC
LIMIT 5;

-- Calculate how many posts each user has created that have been closed or deleted
SELECT 
    U.DisplayName,
    SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedDeletedPosts
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
GROUP BY 
    U.DisplayName
HAVING 
    SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 12) THEN 1 ELSE 0 END) > 1
ORDER BY 
    ClosedDeletedPosts DESC;
