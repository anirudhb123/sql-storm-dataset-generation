WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalQuestionScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS TotalAnswerScore,
        SUM(c.Score) AS TotalCommentScore,
        SUM(b.Class) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        p.AcceptedAnswerId
    FROM Posts p
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagUsage
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY t.TagName
    ORDER BY TagUsage DESC
    LIMIT 10
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.TotalQuestionScore,
    ua.TotalAnswerScore,
    ua.TotalCommentScore,
    ua.TotalBadges,
    ps.Title AS RecentPostTitle,
    ps.ViewCount AS RecentPostViews,
    ps.CreationDate AS RecentPostCreationDate,
    ps.AnswerCount AS RecentPostAnswers,
    ps.CommentCount AS RecentPostComments,
    pt.TagName AS PopularTag,
    pt.TagUsage AS PopularTagUsage
FROM UserActivity ua
JOIN PostStats ps ON ua.UserId = ps.AcceptedAnswerId
CROSS JOIN PopularTags pt
ORDER BY ua.TotalPosts DESC, ua.TotalQuestionScore DESC
LIMIT 50;
