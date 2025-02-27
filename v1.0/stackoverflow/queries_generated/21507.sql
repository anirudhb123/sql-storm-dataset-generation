WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS RecentPostCount,
        COUNT(DISTINCT c.Id) AS RecentCommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id
),
UsersWithRecentActivity AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ura.RecentPostCount, 0) AS RecentPostCount,
        COALESCE(ura.RecentCommentCount, 0) AS RecentCommentCount
    FROM 
        Users u
    LEFT JOIN 
        RecentUserActivity ura ON u.Id = ura.UserId
)
SELECT 
    u.DisplayName,
    up.RecentPostCount,
    up.RecentCommentCount,
    rp.Title AS MostRecentPostTitle,
    rp.CreationDate AS MostRecentPostDate,
    rp.Score AS MostRecentPostScore,
    CASE 
        WHEN rp.PostId IS NULL THEN 'No Posts'
        ELSE 'Has Posts'
    END AS PostStatus
FROM 
    UsersWithRecentActivity up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    (up.RecentPostCount > 0 OR up.RecentCommentCount > 0)
    AND (up.RecentPostCount + up.RecentCommentCount) > (SELECT AVG(RecentPostCount + RecentCommentCount) FROM UsersWithRecentActivity)
ORDER BY 
    up.RecentPostCount DESC,
    up.RecentCommentCount DESC
LIMIT 10;

-- This query retrieves the top 10 users with the most activity (posts/comments) in the last year,
-- presents their most recent post details if available, and provides a status indicating whether they have posts.
-- It showcases CTEs, outer joins, window functions, and complex predicates, while ensuring
-- that only users exceeding the average activity level are displayed.
