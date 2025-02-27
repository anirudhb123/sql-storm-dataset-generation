WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        AVG(v.BountyAmount) AS AverageBounty
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1)
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostOrder
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id
),
UserPostStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        pm.PostId,
        pm.Title,
        pm.CreationDate,
        pm.LastActivityDate,
        pm.Score,
        pm.ViewCount,
        pm.CommentCount,
        RANK() OVER (PARTITION BY us.UserId ORDER BY pm.Score DESC) AS PostRank
    FROM UserStats us
    JOIN PostMetrics pm ON us.UserId = pm.OwnerUserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostId,
    ups.Title,
    COALESCE(ups.Score, 0) AS PostScore,
    COALESCE(ups.ViewCount, 0) AS PostViews,
    ups.CommentCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.AverageBounty,
    CASE 
        WHEN ups.PostRank = 1 THEN 'Best Post' 
        ELSE 'Regular Post' 
    END AS PostStatus
FROM UserPostStats ups
JOIN UserStats us ON ups.UserId = us.UserId
WHERE us.TotalPosts > 0
ORDER BY ups.Score DESC, ups.CommentCount DESC, ups.CreationDate DESC;
