WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(CASE WHEN p.LastActivityDate > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentActivityCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '60 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        pt.Name AS PostType,
        COUNT(ph.Id) AS CloseCount
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, p.Title, pt.Name, ph.CreationDate
),
TagCount AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM Tags t
    JOIN Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.TotalViews,
    u.AvgScore,
    u.RecentActivityCount,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    cp.CloseCount AS ClosedPostsCount,
    tc.TagName,
    tc.PostCount AS TagPopularity
FROM UserActivity u
LEFT JOIN RecentPosts rp ON u.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN ClosedPosts cp ON u.UserId = cp.PostId
LEFT JOIN TagCount tc ON u.PostCount > 0
WHERE u.TotalViews > 100
ORDER BY u.Reputation DESC, u.PostCount DESC;
