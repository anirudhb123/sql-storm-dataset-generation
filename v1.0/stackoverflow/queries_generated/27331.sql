WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    ORDER BY TotalViews DESC
    LIMIT 10
),
UserPostDetails AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.Tags
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.PostTypeId = 1
      AND p.ViewCount > 1000
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ua.TotalBounty,
    pt.TagName,
    pt.TotalViews,
    pt.PostCount,
    updt.Title,
    updt.CreationDate,
    updt.ViewCount AS PopularPostViews,
    updt.Score AS PostScore,
    updt.AnswerCount,
    updt.CommentCount,
    updt.Tags
FROM UserActivity ua
CROSS JOIN PopularTags pt
LEFT JOIN UserPostDetails updt ON ua.UserId = updt.UserId
WHERE ua.TotalPosts > 5 AND ua.TotalComments > 10
ORDER BY ua.TotalBounty DESC, pt.TotalViews DESC;
