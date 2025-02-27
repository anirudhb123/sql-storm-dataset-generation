WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS RankViews
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Badges WHERE UserId = U.Id) AS BadgeCount
    FROM Users U
    WHERE U.CreationDate >= NOW() - INTERVAL '1 month'
),
PostCloseReasons AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstCloseDate,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 10) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) -- Closed and Reopened posts
    GROUP BY PH.PostId
)
SELECT 
    P.Title,
    P.CreationDate,
    P.Score,
    COALESCE(U.DisplayName, 'Unknown') AS OwnerDisplayName,
    COALESCE(PCR.CloseCount, 0) AS TotalClosures,
    CASE 
        WHEN P.ViewCount > 1000 THEN 'Hot Post'
        WHEN P.ViewCount BETWEEN 500 AND 1000 THEN 'Trending Post'
        ELSE 'Normal Post'
    END AS PostStatus,
    CASE 
        WHEN R.RankScore IS NOT NULL AND R.RankScore <= 5 THEN 'Top Ranked'
        ELSE 'Standard Post'
    END AS RankingStatus
FROM RankedPosts R
LEFT JOIN Posts P ON R.PostId = P.Id
LEFT JOIN RecentUsers U ON P.OwnerUserId = U.UserId
LEFT JOIN PostCloseReasons PCR ON P.Id = PCR.PostId
WHERE R.RankScore IS NOT NULL
  AND (U.Reputation IS NULL OR U.Reputation > 50 OR PCR.CloseCount < 2) -- Filter on user reputation and post closure
  AND (P.CreationDate <= NOW() OR P.CreationDate > '2021-01-01') -- Arbitrary historical point
ORDER BY R.RankScore ASC, P.ViewCount DESC
LIMIT 50;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        1 AS Level
    FROM Posts P
    WHERE P.ParentId IS NULL
    UNION ALL
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        PH.Level + 1
    FROM Posts P
    INNER JOIN PostHierarchy PH ON P.ParentId = PH.PostId
)
SELECT 
    Title,
    COUNT(*) FILTER (WHERE Level <= 2) AS DirectAndIndirectDescendants
FROM PostHierarchy
GROUP BY Title
HAVING COUNT(*) > 2
ORDER BY DirectAndIndirectDescendants DESC;
