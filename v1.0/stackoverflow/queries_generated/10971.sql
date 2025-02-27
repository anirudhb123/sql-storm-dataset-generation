-- Performance Benchmarking Query
-- This query retrieves the total number of posts, average score, and average view count, 
-- as well as the top 5 users by reputation.

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgPostScore,
        AVG(ViewCount) AS AvgPostViewCount
    FROM 
        Posts
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.AverageScore,
    us.AverageViewCount,
    ps.TotalPosts AS OverallTotalPosts,
    ps.AvgPostScore AS OverallAvgPostScore,
    ps.AvgPostViewCount AS OverallAvgPostViewCount
FROM 
    UserStats us,
    PostStats ps
ORDER BY 
    us.TotalPosts DESC
LIMIT 5; -- Limiting to top 5 users by total posts
