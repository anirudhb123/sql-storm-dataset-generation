-- Performance benchmarking query to analyze the number of posts, comments, and votes over time

SELECT 
    DATE_TRUNC('month', p.CreationDate) AS Month,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    Month
ORDER BY 
    Month ASC;
