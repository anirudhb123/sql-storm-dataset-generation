WITH RecursivePostCTE AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting with Questions
    
    UNION ALL
    
    SELECT
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostCTE r ON p.ParentId = r.PostId
    WHERE p.PostTypeId = 2  -- Answers related to questions
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(AVG(v.VoteTypeId = 2), 0) AS AverageUpvotes,
        COALESCE(AVG(v.VoteTypeId = 3), 0) AS AverageDownvotes
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY p.Id
)
SELECT
    u.DisplayName,
    up.TotalPosts,
    up.TotalQuestions,
    up.TotalAnswers,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    COUNT(DISTINCT pm.Id) AS PostsInLastYear,
    SUM(pm.ViewCount) AS TotalViews,
    AVG(pm.Score) AS AverageScore,
    SUM(pm.CommentCount) AS TotalComments,
    AVG(pm.AverageUpvotes) AS AvgUpvotes,
    AVG(pm.AverageDownvotes) AS AvgDownvotes,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id AND p.ClosedDate IS NOT NULL) AS ClosedPosts
FROM Users u
INNER JOIN UserStats up ON u.Id = up.UserId
LEFT JOIN PostMetrics pm ON pm.OwnerUserId = u.Id 
GROUP BY u.DisplayName, up.TotalPosts, up.TotalQuestions, up.TotalAnswers, up.GoldBadges, up.SilverBadges, up.BronzeBadges
ORDER BY TotalPosts DESC
LIMIT 100;
