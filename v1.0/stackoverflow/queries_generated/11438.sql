-- Performance Benchmarking Query

-- This query will retrieve user engagement metrics along with post statistics
-- to evaluate performance across the Stack Overflow schema

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,
    SUM(v.VoteTypeId = 3) AS TotalDownVotes,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAcceptableAnswers,
    MAX(p.LastActivityDate) AS LastActive
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts a ON a.ParentId = p.Id -- This counts answers to questions
LEFT JOIN 
    Comments c ON c.UserId = u.Id
LEFT JOIN 
    Votes v ON v.UserId = u.Id AND v.PostId = p.Id
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 100; -- Limiting to top 100 users by reputation for benchmarking
