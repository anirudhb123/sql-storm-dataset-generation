WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.Score IS NOT NULL
),
RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY u.Id, u.DisplayName
),
AggregatedUserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 ELSE NULL END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 ELSE NULL END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 ELSE NULL END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rp.PostCount, 0) AS TotalPosts,
        COALESCE(uba.GoldBadges, 0) AS GoldBadges,
        COALESCE(uba.SilverBadges, 0) AS SilverBadges,
        COALESCE(uba.BronzeBadges, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS PostCount
        FROM Posts
        WHERE PostTypeId = 1
        GROUP BY OwnerUserId
    ) rp ON u.Id = rp.OwnerUserId
    LEFT JOIN AggregatedUserBadges uba ON u.Id = uba.UserId
)

SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges,
    rua.CommentCount,
    rua.UpVoteCount,
    rua.DownVoteCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount
FROM UserPostSummary ups
JOIN RecentUserActivity rua ON ups.UserId = rua.UserId
LEFT JOIN RankedPosts rp ON ups.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE ups.TotalPosts > 0
ORDER BY rua.UpVoteCount DESC, rua.CommentCount DESC, ups.TotalPosts DESC, rp.Score DESC
LIMIT 50;

This query accomplishes a number of things:
1. It ranks posts per user, displaying the user's top post.
2. It aggregates various user activity metrics, including comments and votes within the last 30 days.
3. Badges are aggregated to show how many of each type a user has.
4. The final SELECT statement combines user metrics with their top-ranked post information, showcasing a variety of user engagement metrics.
5. The query uses multiple CTEs for complex logic separation and clarity.
