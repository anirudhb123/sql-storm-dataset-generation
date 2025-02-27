WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE
            WHEN U.Reputation IS NULL THEN 'Unknown Reputation'
            WHEN U.Reputation > 1000 THEN 'High Reputation'
            WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.CreationDate >= NOW() - INTERVAL '30 days' THEN 1 END) AS RecentPostCount,
        AVG(P.Score) AS AveragePostScore,
        MIN(P.CreationDate) AS FirstPostDate,
        MAX(P.CreationDate) AS LastPostDate,
        RANK() OVER (ORDER BY AVG(P.Score) DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.OwnerUserId IS NOT NULL
    GROUP BY 
        P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedPostCount
    FROM 
        Posts P
    WHERE 
        P.Id IN (SELECT PostId FROM PostHistory WHERE PostHistoryTypeId = 10) -- Closed posts
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(R.ReputationCategory, 'Unknown') AS ReputationCategory,
        COALESCE(R.BadgeCount, 0) AS BadgeCount,
        COALESCE(RPS.RecentPostCount, 0) AS RecentPostCount,
        COALESCE(RPS.AveragePostScore, 0) AS AveragePostScore,
        COALESCE(CP.ClosedPostCount, 0) AS ClosedPostCount
    FROM 
        Users U
    LEFT JOIN 
        UserReputation R ON U.Id = R.UserId
    LEFT JOIN 
        RecentPostStats RPS ON U.Id = RPS.OwnerUserId
    LEFT JOIN 
        ClosedPosts CP ON U.Id = CP.OwnerUserId
)
SELECT 
    U.Id,
    U.DisplayName,
    U.ReputationCategory,
    U.BadgeCount,
    U.RecentPostCount,
    U.AveragePostScore,
    U.ClosedPostCount,
    CASE 
        WHEN U.ClosedPostCount = 0 THEN 'No closed posts'
        WHEN U.ClosedPostCount > U.RecentPostCount THEN 'More closed than recent posts'
        ELSE 'Active contributor'
    END AS ActivityStatus
FROM 
    UserPerformance U
WHERE 
    U.BadgeCount > 5
ORDER BY 
    U.AveragePostScore DESC NULLS LAST
LIMIT 10
UNION ALL
SELECT 
    U.Id,
    U.DisplayName,
    'Inactive User' AS ReputationCategory, 
    0 AS BadgeCount,
    0 AS RecentPostCount,
    0 AS AveragePostScore,
    0 AS ClosedPostCount,
    'No activity' AS ActivityStatus
FROM 
    Users U
WHERE 
    U.LastAccessDate < NOW() - INTERVAL '1 year'
  AND NOT EXISTS (
      SELECT 1 FROM Posts P WHERE P.OwnerUserId = U.Id
  )
ORDER BY 
    AveragePostScore DESC NULLS LAST;
