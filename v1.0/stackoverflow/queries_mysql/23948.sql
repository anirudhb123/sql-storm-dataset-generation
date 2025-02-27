
WITH UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(CASE WHEN COALESCE(P.Score, 0) > 0 THEN 1 ELSE 0 END), 0) AS Upvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentActivity AS (
    SELECT
        OwnerUserId AS UserId,
        COUNT(*) AS RecentActivePosts
    FROM Posts
    WHERE CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY OwnerUserId
),
TopBadges AS (
    SELECT 
        UserId,
        GROUP_CONCAT(Name SEPARATOR ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
)
SELECT
    U.Id AS UserID,
    U.DisplayName,
    U.Reputation,
    COALESCE(UE.TotalPosts, 0) AS TotalPosts,
    COALESCE(UE.Questions, 0) AS Questions,
    COALESCE(UE.Answers, 0) AS Answers,
    COALESCE(UE.Upvotes, 0) AS Upvotes,
    COALESCE(RA.RecentActivePosts, 0) AS RecentActivePosts,
    COALESCE(TB.BadgeNames, '') AS BadgeNames,
    CASE 
        WHEN COALESCE(U.Reputation, 0) >= 1000 THEN 'High Reputation'
        WHEN COALESCE(U.Reputation, 0) BETWEEN 500 AND 999 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationTier,
    CASE
        WHEN EXISTS(SELECT 1 FROM Comments C WHERE C.UserId = U.Id AND C.CreationDate < NOW() - INTERVAL 60 DAY) THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM Users U
LEFT JOIN UserEngagement UE ON U.Id = UE.UserId
LEFT JOIN RecentActivity RA ON U.Id = RA.UserId
LEFT JOIN TopBadges TB ON U.Id = TB.UserId
WHERE U.Reputation > 0
ORDER BY U.Reputation DESC
LIMIT 100;
