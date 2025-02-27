WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBountyEarned
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TagActivity AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TotalPostsWithTag,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestionsWithTag,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswersWithTag
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY t.TagName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY p.Id, u.DisplayName
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalBadges,
    ua.TotalBountyEarned,
    ta.TagName,
    ta.TotalPostsWithTag,
    ta.TotalQuestionsWithTag,
    ta.TotalAnswersWithTag,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.TotalComments
FROM UserActivity ua
CROSS JOIN TagActivity ta
JOIN PostStatistics ps ON ps.OwnerUserId = ua.UserId
ORDER BY ua.TotalPosts DESC, ps.Score DESC, ta.TotalPostsWithTag DESC;

