-- Performance benchmarking query on StackOverflow schema

WITH UserStats AS (
    SELECT 
        Id AS UserId,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT Id) AS PostsCount,
        COUNT(DISTINCT CASE WHEN Reputation > 0 THEN Id END) AS PositiveReputationPosts
    FROM Users
    GROUP BY Id
), PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore,
        COUNT(DISTINCT CASE WHEN IsModeratorOnly = 1 THEN Id END) AS TotalModeratorTags
    FROM Posts
    JOIN Tags ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.TotalUpVotes,
    us.TotalDownVotes,
    ps.TotalPosts,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalViews,
    ps.TotalScore,
    ps.TotalModeratorTags
FROM Users u
LEFT JOIN UserStats us ON u.Id = us.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
ORDER BY ps.TotalPosts DESC
LIMIT 100; -- Top 100 users by post count for benchmarking
