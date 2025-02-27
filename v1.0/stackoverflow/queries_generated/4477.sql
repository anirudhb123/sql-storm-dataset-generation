WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(B.Class, 0)) AS BadgeLevel,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS ClosureCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.PositivePosts,
    U.NegativePosts,
    COALESCE(RP.Title, 'No recent posts') AS RecentPostTitle,
    COALESCE(RP.CreationDate, 'N/A') AS RecentPostDate,
    COALESCE(CP.ClosureCount, 0) AS TotalClosures,
    COALESCE(CP.LastClosedDate, 'Never') AS LastClosed
FROM UserStats U
LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId AND RP.RecentPostRank = 1
LEFT JOIN ClosedPosts CP ON RP.PostId = CP.PostId
WHERE U.Reputation > 1000
ORDER BY U.Rank, U.Reputation DESC;
