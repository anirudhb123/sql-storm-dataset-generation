WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           p.AcceptedAnswerId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Question posts
    AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT u.Id AS UserId,
           u.Reputation,
           u.DisplayName,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
TagStatistics AS (
    SELECT UNNEST(STRING_TO_ARRAY(Tags, '<>')) AS Tag,
           COUNT(*) AS TagCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY UNNEST(STRING_TO_ARRAY(Tags, '<>'))
),
CloseReasonCounts AS (
    SELECT ph.PostId,
           COUNT(*) AS CloseCount,
           STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS SMALLINT)
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
),
CombinedStats AS (
    SELECT up.PostId,
           up.Title,
           us.DisplayName,
           us.Reputation,
           us.BadgeCount,
           us.PositiveScorePosts,
           ts.Tag,
           ts.TagCount,
           crc.CloseCount,
           crc.CloseReasonNames
    FROM RankedPosts up
    LEFT JOIN UserStats us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = up.PostId)
    LEFT JOIN TagStatistics ts ON ts.Tag IN (SELECT UNNEST(STRING_TO_ARRAY(Tags, '<>')) FROM Posts WHERE Id = up.PostId)
    LEFT JOIN CloseReasonCounts crc ON crc.PostId = up.PostId
    WHERE up.RN <= 2 -- Only taking latest 2 posts per user for analysis
)
SELECT c.PostId,
       c.Title,
       c.DisplayName,
       COALESCE(c.Reputation, 0) AS Reputation,
       COALESCE(c.BadgeCount, 0) AS BadgeCount,
       COALESCE(c.PositiveScorePosts, 0) AS PositiveScorePosts,
       COALESCE(c.CloseCount, 0) AS CloseCount,
       COALESCE(c.CloseReasonNames, 'No Close Reasons') AS CloseReasonNames,
       CASE WHEN c.TagCount IS NOT NULL THEN CONCAT('Popular Tag: ', c.Tag)
            ELSE 'No Tags Found' END AS TagInfo
FROM CombinedStats c
ORDER BY c.Reputation DESC, c.CloseCount DESC
LIMIT 50;

-- This query performs detailed performance benchmarking by analyzing recent question posts, user statistics, 
-- tag statistics, and closure reasons. It integrates multiple CTEs, window functions, and aggregate functions 
-- to produce insightful results for performance analysis, making it both comprehensive and intricate.
