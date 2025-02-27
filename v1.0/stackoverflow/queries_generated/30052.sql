WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        1 AS Level,
        U.CreationDate
    FROM Users U
    WHERE U.Reputation > 1000 -- Filter for users with significant reputation

    UNION ALL

    SELECT 
        U.Id AS UserId,
        U.Reputation,
        UR.Level + 1,
        U.CreationDate
    FROM Users U
    INNER JOIN UserReputation UR ON U.Id = UR.UserId
    WHERE UR.Reputation < U.Reputation -- Continue to find users with higher reputation
),

InactivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.LastActivityDate,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS RecentActivityRank
    FROM Posts P
    WHERE P.LastActivityDate < NOW() - INTERVAL '6 months' -- Inactive posts over 6 months
),

ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason,
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    INNER JOIN CloseReasonTypes C ON PH.PostHistoryTypeId = 10 AND PH.Comment = C.Id::varchar
    GROUP BY PH.PostId, C.Name, PH.CreationDate
),

UserWithBadges AS (
    SELECT 
        U.Id AS UserId,
        B.Name AS BadgeName,
        B.Class,
        COUNT(*) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId AND B.Class = 1 -- Count only gold badges
    GROUP BY U.Id, B.Name, B.Class
)

SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    COALESCE(B.BadgeCount, 0) AS GoldBadgeCount,
    P.PostId,
    P.Title AS PostTitle,
    P.ViewCount,
    COALESCE(Closed.CloseCount, 0) AS CloseCount,
    R.ColumnCount AS RecentPostCount
FROM Users U
LEFT JOIN UserWithBadges B ON U.Id = B.UserId
LEFT JOIN InactivePosts P ON U.Id = P.PostId -- Join inactive posts for the associated user
LEFT JOIN ClosedPosts Closed ON P.PostId = Closed.PostId
LEFT JOIN (
    SELECT 
        OwnerUserId,
        COUNT(*) AS ColumnCount
    FROM Posts
    GROUP BY OwnerUserId
) R ON U.Id = R.OwnerUserId
WHERE U.Reputation > (SELECT AVG(Reputation) FROM Users) -- Above average reputation
ORDER BY U.Reputation DESC, GoldBadgeCount DESC, ViewCount DESC;
