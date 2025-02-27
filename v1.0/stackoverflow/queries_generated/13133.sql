-- Performance benchmarking query for StackOverflow schema

-- This query retrieves various metrics about posts, along with user and post type information
-- to analyze performance across different post categories and user activities.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    AVG(p.ViewCount) AS AvgViewsPerPost,
    SUM(p.AnswerCount) AS TotalAnswers,
    SUM(p.CommentCount) AS TotalComments,
    SUM(CASE WHEN p.FavoriteCount > 0 THEN 1 ELSE 0 END) AS FavoritePosts,
    COUNT(DISTINCT u.Id) AS UniqueUsers,
    SUM(CASE WHEN u.Reputation > 1000 THEN 1 ELSE 0 END) AS HighReputationUsers
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
WHERE
    p.CreationDate >= '2020-01-01' -- Adjust date range as necessary for benchmarking
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;

-- This query provides insights into the relationship between post types and user interactions
-- for effective benchmarking of the platform's performance.
