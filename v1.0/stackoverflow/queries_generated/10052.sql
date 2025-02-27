-- Performance Benchmarking Query

-- This query retrieves the top 10 users with the highest reputation,
-- along with their total number of posts, answers and comments.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId  -- Counting all posts created by the user
LEFT JOIN 
    Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2  -- Counting only answers (PostTypeId = 2)
LEFT JOIN 
    Comments c ON u.Id = c.UserId  -- Counting all comments made by the user
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;
