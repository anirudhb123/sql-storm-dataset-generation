-- Performance Benchmarking Query for the Stack Overflow Schema

-- This query retrieves the count of posts, average score, and average view count for each post type.
-- It also includes the total number of users and badges, to evaluate the relationships between posts and user achievements.

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount, 
    AVG(p.Score) AS AverageScore, 
    AVG(p.ViewCount) AS AverageViewCount,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
