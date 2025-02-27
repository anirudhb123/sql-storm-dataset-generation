-- Performance Benchmarking Query

-- This query retrieves the average score of posts, the total number of posts, and the count of unique users who own these posts.
-- It compares these metrics across different post types to evaluate their performance.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;  -- Order by the number of posts
