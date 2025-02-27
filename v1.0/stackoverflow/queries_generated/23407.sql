WITH UserStatistics AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 100
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    WHERE P.CreationDate > CURRENT_DATE - INTERVAL '90 days'
    GROUP BY P.OwnerUserId
),
OverallStatistics AS (
    SELECT
        U.UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UP.TotalUpvotes, 0) AS TotalUpvotes,
        COALESCE(UP.TotalDownvotes, 0) AS TotalDownvotes,
        COALESCE(RP.TotalPosts, 0) AS TotalRecentPosts,
        COALESCE(RP.TotalViews, 0) AS TotalViews,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM UserStatistics U
    LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId
)

SELECT
    O.UserId,
    O.DisplayName,
    O.Reputation,
    O.TotalUpvotes,
    O.TotalDownvotes,
    O.TotalRecentPosts,
    O.TotalViews,
    O.GoldBadges,
    O.SilverBadges,
    O.BronzeBadges,
    O.UserRank,
    CASE 
        WHEN O.TotalUpvotes > O.TotalDownvotes THEN 'Positive Contributor'
        WHEN O.TotalUpvotes < O.TotalDownvotes THEN 'Needs Improvement'
        ELSE 'Balanced Contributor'
    END AS ContributorType,
    CASE 
        WHEN O.TotalRecentPosts = 0 THEN 'No Recent Activity'
        WHEN O.TotalRecentPosts < 5 THEN 'Moderate Activity'
        ELSE 'Active User'
    END AS ActivityLevel
FROM OverallStatistics O
WHERE O.Reputation IS NOT NULL
AND O.TotalUpvotes > 0
ORDER BY O.UserRank
LIMIT 50;

-- Additional queries for benchmarking

SELECT
    P.Id,
    P.Title,
    P.ViewCount,
    DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS ViewRank
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE U.Reputation > 100
AND P.CreationDate < CURRENT_DATE - INTERVAL '30 days'
ORDER BY ViewRank, P.ViewCount DESC;

SELECT DISTINCT
    P.Id AS PostId,
    T.TagName,
    CASE 
        WHEN PH.Comment IS NOT NULL THEN 'Edited'
        ELSE 'Unedited'
    END AS EditStatus
FROM Posts P
JOIN Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)
WHERE T.Count > 10
AND P.CreationDate >= '2023-01-01'
ORDER BY T.TagName;

WITH RecursivePostHierarchy AS (
    SELECT
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        1 AS Level
    FROM Posts P
    WHERE P.ParentId IS NULL

    UNION ALL

    SELECT
        P.Id,
        P.ParentId,
        P.Title,
        Level + 1
    FROM Posts P
    JOIN RecursivePostHierarchy R ON P.ParentId = R.PostId
)
SELECT
    PostId,
    Title,
    Level
FROM RecursivePostHierarchy
ORDER BY Level, PostId;
