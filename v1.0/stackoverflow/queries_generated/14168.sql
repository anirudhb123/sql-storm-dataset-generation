-- Performance Benchmarking SQL Query

-- Measure the time taken for the join operations and aggregate functions
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        AVG(p.Score) AS AveragePostScore,
        SUM(p.ViewCount) AS TotalViewCount,
        SUM(p.CommentCount) AS TotalCommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.AveragePostScore,
    u.TotalViewCount,
    u.TotalCommentCount
FROM 
    UserPostStats u
ORDER BY 
    u.TotalPosts DESC
LIMIT 100;

-- Additional benchmarking with Votes, Posts, and Comments
SELECT 
    p.Id AS PostId,
    COUNT(v.Id) AS TotalVotes,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id
ORDER BY 
    TotalVotes DESC
LIMIT 100;

-- Benchmarking for Badges awarded to users by class
SELECT 
    b.UserId,
    b.Class,
    COUNT(b.Id) AS TotalBadges
FROM 
    Badges b
GROUP BY 
    b.UserId, b.Class
ORDER BY 
    TotalBadges DESC;

