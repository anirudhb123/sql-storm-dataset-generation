-- Performance benchmarking query to analyze user activity and engagement metrics on posts with joins across several tables.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
    SUM(v.VoteTypeId = 2) AS TotalUpvotes,
    SUM(v.VoteTypeId = 3) AS TotalDownvotes,
    SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
    AVG(p.Score) AS AveragePostScore,
    MAX(p.CreationDate) AS LatestPostDate    
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 0  -- Considering only active users with reputation
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC;
