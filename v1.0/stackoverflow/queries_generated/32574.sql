WITH RecursivePostStats AS (
    -- Recursive CTE to calculate the depth of posts and aggregate views
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        0 AS Depth,
        COALESCE((SELECT COUNT(*) FROM Posts WHERE ParentId = p.Id), 0) AS AnswerCount
    FROM Posts p
    WHERE p.PostTypeId = 1

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        r.Depth + 1,
        COALESCE((SELECT COUNT(*) FROM Posts WHERE ParentId = p.Id), 0) AS AnswerCount
    FROM Posts p
    JOIN RecursivePostStats r ON p.ParentId = r.PostId
),
PostViewRanks AS (
    -- CTE for ranking posts based on their view count and depth
    SELECT 
        PostId,
        Title,
        ViewCount,
        Depth,
        RANK() OVER (PARTITION BY Depth ORDER BY ViewCount DESC) AS RankByViews
    FROM RecursivePostStats
),
UserBadgeCounts AS (
    -- CTE to count badges by user
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
FilteredPosts AS (
    -- Filtering posts only involving active users with a certain badge count
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.BadgeCount,
        COALESCE(u.Location, 'Unknown') AS UserLocation
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE u.Reputation > 1000 AND u.BadgeCount > 3
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    pv.Depth,
    pv.RankByViews,
    u.Location AS UserLocation,
    u.LastAccessDate,
    CASE 
        WHEN u.LastAccessDate < NOW() - INTERVAL '30 days' THEN 'Inactive'
        ELSE 'Active' 
    END AS UserStatus
FROM FilteredPosts f
JOIN PostViewRanks pv ON f.PostId = pv.PostId
JOIN Users u ON f.OwnerUserId = u.Id
WHERE pv.RankByViews <= 5 -- Top 5 posts by view count for each depth
ORDER BY pv.Depth, pv.RankByViews;
