-- Performance benchmarking query: Retrieve the number of posts, the average score of posts, and the number of users who have posted, grouped by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT p.OwnerUserId) AS TotalUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    TotalPosts DESC;
