-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves a summary of posts, including the number of answers and votes by post type,
-- and aggregates user reputation information to assess performance across various types.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    SUM(v.UpVotes) AS TotalUpVotes,
    SUM(v.DownVotes) AS TotalDownVotes,
    AVG(u.Reputation) AS AverageUserReputation,
    MIN(p.CreationDate) AS EarliestPostDate,
    MAX(p.CreationDate) AS LatestPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Posts a ON p.Id = a.ParentId  -- Join to count answers related to questions
LEFT JOIN 
    Votes v ON p.Id = v.PostId     -- Join to aggregate votes
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id -- Join to retrieve user reputation data
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
