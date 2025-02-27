WITH RecursivePostCTE AS (
    -- CTE to find parent posts and their hierarchy
    SELECT Id, ParentId, Title, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    
    UNION ALL
    
    SELECT p.Id, p.ParentId, p.Title, rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostCTE rp ON p.ParentId = rp.Id
),
UserVoteCounts AS (
    -- Aggregate to count votes and views for users
    SELECT
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY u.Id
),
PostHistoryAggregated AS (
    -- Aggregation of post history types
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
MostActiveUsers AS (
    -- Find the most active users based on post contributions
    SELECT
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.CreatedAt >= NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentPostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
    HAVING COUNT(p.Id) > 5
)
-- Final query to join all components and present comprehensive data
SELECT
    up.DisplayName AS UserDisplayName,
    up.UpVotesCount,
    up.DownVotesCount,
    up.TotalViews,
    ph.PostId,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS CloseCount,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (24, 52) THEN ph.PostId END) AS EditCount,
    r.Title AS ParentTitle,
    ma.PostCount,
    ma.RecentPostCount
FROM UserVoteCounts up
LEFT JOIN PostHistoryAggregated ph ON up.UserId = ph.UserId
LEFT JOIN RecursivePostCTE r ON ph.PostId = r.Id
LEFT JOIN MostActiveUsers ma ON up.UserId = ma.UserId
GROUP BY up.UserId, r.Title, ph.PostId, ma.PostCount, ma.RecentPostCount
ORDER BY up.TotalViews DESC, up.UpVotesCount DESC
LIMIT 100;
