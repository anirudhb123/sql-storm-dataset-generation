WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Tags) AS UsageCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY t.TagName
    ORDER BY COUNT(p.Tags) DESC
    LIMIT 10
),
UserTags AS (
    SELECT
        ua.UserId,
        ut.TagName
    FROM UserActivity ua
    JOIN Posts p ON ua.UserId = p.OwnerUserId
    JOIN Tags ut ON p.Tags LIKE CONCAT('%<', ut.TagName, '>%')
)

SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalViews,
    ua.TotalScore,
    ua.TotalBadges,
    STRING_AGG(DISTINCT ut.TagName, ', ') AS Tags,
    pt.UsageCount AS TagUsageCount
FROM UserActivity ua
LEFT JOIN UserTags ut ON ua.UserId = ut.UserId
LEFT JOIN PopularTags pt ON ut.TagName = pt.TagName
GROUP BY ua.UserId, ua.DisplayName, pt.UsageCount
HAVING ua.TotalPosts > 0
ORDER BY ua.TotalScore DESC, ua.TotalPosts DESC;
