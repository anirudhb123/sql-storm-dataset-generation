WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagUsageCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>') -- Search for the tag within the Tags field
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE pt.Name = 'Question' -- Only considering Questions for tags
    GROUP BY t.TagName
    ORDER BY TagUsageCount DESC
    LIMIT 5
),
UserBadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalViews,
    ups.TotalScore,
    COALESCE(ubs.TotalBadges, 0) AS TotalBadges,
    GROUP_CONCAT(pt.TagName) AS PopularTags
FROM UserPostStats ups
LEFT JOIN UserBadgeStats ubs ON ups.UserId = ubs.UserId
LEFT JOIN PopularTags pt ON pt.TagUsageCount > 0
GROUP BY ups.UserId, ups.DisplayName, ups.TotalPosts, ups.TotalQuestions, ups.TotalAnswers, ups.TotalViews, ups.TotalScore, ubs.TotalBadges
ORDER BY ups.TotalScore DESC, ups.TotalPosts DESC;
