WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.CommentCount) AS AvgCommentsPerPost
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS RelatedPostsCount
    FROM Tags t
    JOIN Posts pt ON t.Id = ANY(string_to_array(pt.Tags, '>')::int[])
    GROUP BY t.TagName
    ORDER BY RelatedPostsCount DESC
    LIMIT 5
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.TotalViews,
    ups.AvgCommentsPerPost,
    ubc.BadgeCount,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges,
    tt.TagName,
    tt.RelatedPostsCount
FROM UserPostStats ups
LEFT JOIN UserBadgeCounts ubc ON ups.UserId = ubc.UserId
CROSS JOIN TopTags tt
WHERE ups.TotalPosts > 0
ORDER BY ups.TotalScore DESC, ups.TotalPosts DESC, ubc.BadgeCount DESC;
