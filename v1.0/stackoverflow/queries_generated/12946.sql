-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the total number of posts, along with their average score and views, 
-- categorized by post type, and the total number of users and badges. 

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.Score) AS AverageScore, 
    AVG(p.ViewCount) AS AverageViews,
    (SELECT COUNT(DISTINCT u.Id) FROM Users u) AS TotalUsers,
    (SELECT COUNT(b.Id) FROM Badges b) AS TotalBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
