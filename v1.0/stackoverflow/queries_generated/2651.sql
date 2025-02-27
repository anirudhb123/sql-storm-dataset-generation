WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(up.UserId, -1) AS UpVoterId,
        COALESCE(down.UserId, -1) AS DownVoterId
    FROM Posts p
    LEFT JOIN Votes up ON p.Id = up.PostId AND up.VoteTypeId = 2
    LEFT JOIN Votes down ON p.Id = down.PostId AND down.VoteTypeId = 3
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
), RecentBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    WHERE b.Date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY b.UserId
), UserPostStatistics AS (
    SELECT
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(rb.BadgeCount, 0) AS RecentBadgesCount,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN RecentBadges rb ON u.Id = rb.UserId
    GROUP BY u.DisplayName
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.RecentBadgesCount,
    ups.HighViewCountPosts,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.Id) AS CommentCount
FROM UserPostStatistics ups
JOIN RankedPosts rp ON ups.TotalPosts > 5
WHERE rp.Rank <= 3
ORDER BY ups.TotalPosts DESC, rp.Score DESC
LIMIT 10;
