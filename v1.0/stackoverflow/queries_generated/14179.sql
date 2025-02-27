-- Performance benchmarking for Stack Overflow schema
-- This query retrieves the count of posts, average score, and average view count
-- per post type, along with the total number of votes received.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
