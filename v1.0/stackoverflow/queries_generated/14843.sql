-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the count of posts grouped by PostType and the average score of those posts,
-- along with the total number of users who interacted with those posts.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT p.OwnerUserId) AS TotalUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2022-01-01' -- Consider posts created in the year 2022 and later
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
