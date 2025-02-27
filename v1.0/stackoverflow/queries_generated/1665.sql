WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
),
UserScores AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(COALESCE(P.Score, 0)), 0) AS TotalScore,
        MAX(COALESCE(B.GoldBadges, 0)) AS GoldBadges,
        MAX(COALESCE(B.SilverBadges, 0)) AS SilverBadges,
        MAX(COALESCE(B.BronzeBadges, 0)) AS BronzeBadges
    FROM Users U
    LEFT JOIN RecentPosts P ON U.Id = P.OwnerUserId
    LEFT JOIN UserBadges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalScore,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges
FROM UserScores U
JOIN Users UDetails ON U.UserId = UDetails.Id
WHERE U.Reputation > 1000
  AND (U.GoldBadges > 0 OR U.SilverBadges > 0)
ORDER BY U.TotalScore DESC, U.Reputation DESC
LIMIT 10;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        1 AS Depth
    FROM Posts P
    WHERE P.ParentId IS NULL

    UNION ALL

    SELECT 
        P2.Id,
        P2.Title,
        P2.ParentId,
        PH.Depth + 1
    FROM Posts P2
    JOIN PostHierarchy PH ON P2.ParentId = PH.PostId
)
SELECT 
    Depth,
    COUNT(*) AS PostCount
FROM PostHierarchy
GROUP BY Depth
ORDER BY Depth;
