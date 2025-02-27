WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
), RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Date AS BadgeDate
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '6 months'
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
        (SELECT SUM(p.ViewCount) FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalViews,
        COALESCE(rb.BadgeCount, 0) AS RecentBadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            RecentBadges
        GROUP BY 
            UserId
    ) rb ON u.Id = rb.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.TotalViews,
    ua.RecentBadgeCount,
    COALESCE(rp.Title, 'No recent posts') AS RecentPostTitle,
    COALESCE(rp.CreationDate, 'N/A') AS RecentPostDate,
    COUNT(DISTINCT c.Id) FILTER (WHERE c.Score > 0) AS PositiveCommentsCount
FROM 
    UserActivity ua
LEFT JOIN RankedPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN Comments c ON rp.PostId = c.PostId
GROUP BY 
    ua.UserId, ua.DisplayName, ua.Reputation, ua.PostCount, ua.TotalViews, ua.RecentBadgeCount, rp.Title, rp.CreationDate
ORDER BY 
    ua.Reputation DESC, ua.TotalViews DESC;
