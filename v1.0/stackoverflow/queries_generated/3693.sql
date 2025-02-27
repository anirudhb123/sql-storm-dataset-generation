WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(bs.TotalBadges, 0) AS TotalBadges,
        bs.GoldBadges,
        bs.SilverBadges,
        bs.BronzeBadges,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN UserBadgeStats bs ON u.Id = bs.UserId
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalBadges,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.UserRank
FROM UserActivity ua
WHERE ua.TotalPosts > 5
  AND ua.Reputation > 100
ORDER BY ua.UserRank, ua.Reputation DESC
LIMIT 10;

WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
RankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpvoteCount,
        RANK() OVER (ORDER BY rp.UpvoteCount DESC, rp.CommentCount DESC) AS Rank
    FROM RecentPosts rp
)
SELECT 
    rp.Title,
    rp.CommentCount,
    rp.UpvoteCount,
    CASE 
        WHEN rp.UpvoteCount IS NULL THEN 'No Upvotes'
        WHEN rp.CommentCount = 0 THEN 'No Comments'
        ELSE 'Active Engagement'
    END AS EngagementStatus
FROM RankedPosts rp
WHERE rp.Rank <= 5;
