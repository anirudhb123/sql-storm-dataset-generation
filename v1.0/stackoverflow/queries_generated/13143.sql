-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the total number of posts, the average score of questions, 
-- the number of users who contributed posts, and the count of closed posts for benchmarking.

SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AvgQuestionScore,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    COUNT(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 END) AS ClosedPostsCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filtering for posts created in the last year
GROUP BY 
    DATE_TRUNC('month', p.CreationDate) -- Grouping by month for performance analysis of trends
ORDER BY 
    DATE_TRUNC('month', p.CreationDate);
