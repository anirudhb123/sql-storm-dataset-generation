-- Performance Benchmarking Query
-- This query retrieves user statistics alongside their posts, including total posts, average score, and recent activity.

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        MAX(p.LastActivityDate) AS MostRecentActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        Id AS PostId,
        Title,
        CreationDate,
        ViewCount,
        AnswerCount,
        CommentCount
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '30 days' -- posts created in the last 30 days
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.AverageScore,
    us.MostRecentActivity,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.TotalPosts DESC, us.AverageScore DESC;
