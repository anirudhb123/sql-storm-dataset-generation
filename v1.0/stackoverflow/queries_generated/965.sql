WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(RP.Title, 'No Recent Posts') AS RecentPost,
    COALESCE(RP.CreationDate, 'N/A') AS PostDate,
    UB.BadgeCount,
    UB.BadgeNames,
    U.ReputationRank
FROM UserReputation U
LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId AND RP.PostRank = 1
LEFT JOIN UserBadges UB ON U.UserId = UB.UserId
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC
LIMIT 10;

WITH RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(*) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY V.PostId
)
SELECT 
    P.Title,
    P.ViewCount,
    RV.UpVotes,
    RV.DownVotes,
    (RV.UpVotes - RV.DownVotes) AS NetScore
FROM Posts P
LEFT JOIN RecentVotes RV ON P.Id = RV.PostId
WHERE P.ViewCount > 1000
ORDER BY NetScore DESC
LIMIT 5;

SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS PostCount,
    SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount
FROM Posts P
JOIN PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY PT.Name
HAVING COUNT(P.Id) > 50
ORDER BY PostCount DESC;
