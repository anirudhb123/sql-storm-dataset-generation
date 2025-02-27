WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), 
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
        AVG(P.ViewCount) AS AverageViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        CAST(PH.Comment AS INT) AS CloseReasonId
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PR.PostCount, 0) AS TotalPosts,
        COALESCE(PR.PositiveScoredPosts, 0) AS PositivePosts,
        COALESCE(PR.AverageViews, 0) AS AvgViewCount
    FROM Users U
    LEFT JOIN PostStatistics PR ON U.Id = PR.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(P.PostCount, 0) AS TotalPosts,
    COALESCE(P.PositivePosts, 0) AS PositivePosts,
    COALESCE(P.AvgViewCount, 0) AS AvgViewCount,
    COALESCE(C.ClosedCount, 0) AS ClosedPostsCount,
    CASE
        WHEN U.Reputation > 1000 THEN 'High Reputation'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    STRING_AGG(DISTINCT C.CloseReasonId::text, ', ') AS ClosedPostReasons
FROM ActiveUsers U
LEFT JOIN (
    SELECT 
        OwnerUserId,
        COUNT(*) AS ClosedCount
    FROM ClosedPosts CP
    JOIN Posts P ON CP.PostId = P.Id
    GROUP BY OwnerUserId
) C ON U.UserId = C.OwnerUserId
LEFT JOIN PostStatistics P ON U.UserId = P.OwnerUserId
GROUP BY U.UserId, U.DisplayName, U.Reputation
HAVING COALESCE(P.PostCount, 0) > 0
ORDER BY U.Reputation DESC, TotalPosts DESC
LIMIT 100;

