WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.Score) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),

ActivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY ph.PostId, ph.PostHistoryTypeId, ph.UserDisplayName
),

BadgeSummary AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Date >= NOW() - INTERVAL '1 year'
    GROUP BY b.UserId
)

SELECT 
    upc.UserId,
    upc.DisplayName,
    COALESCE(upc.PostCount, 0) AS TotalPosts,
    COALESCE(upc.PositivePosts, 0) AS PositivePostCount,
    COALESCE(upc.NegativePosts, 0) AS NegativePostCount,
    COALESCE(upc.AvgScore, 0) AS AveragePostScore,
    bs.BadgeCount,
    bs.BadgeNames,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.UserId = upc.UserId AND v.CreationDate >= NOW() - INTERVAL '1 month') AS VoteCount,
    (SELECT COUNT(*) 
     FROM ActivePostHistory aph 
     WHERE aph.PostHistoryTypeId = 10 AND aph.UserDisplayName = upc.DisplayName) AS CloseVoteCount
FROM UserPostCounts upc
LEFT JOIN BadgeSummary bs ON upc.UserId = bs.UserId
ORDER BY TotalPosts DESC, BadgeCount DESC
LIMIT 50;

-- Additional filtering based on exotic semantics
HAVING Ace >= 1 OR (TotalPosts IS NULL AND PositivePostCount = 0 AND NegativePostCount IS NULL)

This SQL query integrates various constructs including CTEs, aggregations, string functions, outer joins, nested subqueries, and sophisticated filtering logic, catering to the performance benchmarking an extensive dataset may require. It aims to provide insights into user activity, post history within the last month, and badge counts within the last year—all while accommodating NULL handling and employing just complex enough conditions to promote optimization challenges.
