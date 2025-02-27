WITH UserAggregates AS (
    SELECT 
        U.Id as UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS PositiveScore,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.Score,
        PH.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY PH.UserId ORDER BY PH.CreationDate DESC) AS RecentActionRank
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.PositiveScore,
        UA.BadgeCount,
        UA.LastPostDate,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC) AS Rank
    FROM UserAggregates UA
    WHERE UA.PostCount > 10
)
SELECT 
    U.*,
    COALESCE(RPH.Title, 'No Recent Activity') AS RecentActivityTitle,
    COALESCE(RPH.Score, 0) AS RecentActivityScore
FROM TopUsers U
LEFT JOIN RecentPostHistory RPH ON U.UserId = RPH.UserId AND RPH.RecentActionRank = 1
WHERE U.Rank <= 10
ORDER BY U.Reputation DESC;

-- Now we add a section to include those who have been active but haven't posted recent stats.
UNION ALL

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    0 AS PostCount,
    0 AS PositiveScore,
    0 AS BadgeCount,
    NULL AS LastPostDate,
    'Inactive' AS ActivityStatus
FROM Users U
WHERE U.Id NOT IN (SELECT UserId FROM TopUsers) AND U.Reputation > 50
ORDER BY U.Reputation DESC;
