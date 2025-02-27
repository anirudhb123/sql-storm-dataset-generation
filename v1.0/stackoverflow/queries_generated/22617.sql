WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS QuestionCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    GROUP BY U.Id, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        UR.TotalBounty,
        UR.BadgeCount,
        UR.QuestionCount,
        COALESCE(RP.PostCount, 0) AS RecentPostCount
    FROM UserReputation UR
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(PostId) AS PostCount
        FROM RecentPosts
        WHERE PostRank <= 10
        GROUP BY OwnerUserId
    ) RP ON UR.UserId = RP.OwnerUserId
)
SELECT 
    UA.UserId,
    UA.Reputation,
    UA.TotalBounty,
    UA.BadgeCount,
    UA.QuestionCount,
    UA.RecentPostCount,
    CASE 
        WHEN UA.Reputation >= 1000 THEN 'High Reputation'
        WHEN UA.Reputation >= 100 THEN 'Moderate Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN UA.RecentPostCount = 0 THEN 'No Recent Posts'
        ELSE 'Active User'
    END AS UserActivityStatus
FROM UserActivity UA
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(DISTINCT PostId) AS ClosedPosts
    FROM PostHistory PH 
    WHERE PH.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY UserId
) ClosedP ON UA.UserId = ClosedP.UserId
ORDER BY UA.Reputation DESC, UA.BadgeCount DESC
LIMIT 100;

-- Additionally, collecting users who have more than a certain percentage of their questions closed
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    (COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) * 100.0 / COUNT(P.Id)) AS PercentageClosed
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
LEFT JOIN PostHistory PH ON P.Id = PH.PostId
GROUP BY U.Id, U.DisplayName
HAVING (COUNT(P.Id) > 0 AND PercentageClosed > 50)
ORDER BY PercentageClosed DESC;
