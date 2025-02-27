
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
        @RecentActionRank := IF(@prevUserId = PH.UserId, @RecentActionRank + 1, 1) AS RecentActionRank,
        @prevUserId := PH.UserId
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    CROSS JOIN (SELECT @prevUserId := NULL, @RecentActionRank := 0) AS vars
    WHERE PH.CreationDate >= '2023-10-01 12:34:56'
    ORDER BY PH.UserId, PH.CreationDate DESC
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
        @Rank := @Rank + 1 AS Rank
    FROM UserAggregates UA
    CROSS JOIN (SELECT @Rank := 0) AS vars
    WHERE UA.PostCount > 10
    ORDER BY UA.Reputation DESC
)
SELECT 
    U.*,
    COALESCE(RPH.Title, 'No Recent Activity') AS RecentActivityTitle,
    COALESCE(RPH.Score, 0) AS RecentActivityScore
FROM TopUsers U
LEFT JOIN RecentPostHistory RPH ON U.UserId = RPH.UserId AND RPH.RecentActionRank = 1
WHERE U.Rank <= 10
ORDER BY U.Reputation DESC;
