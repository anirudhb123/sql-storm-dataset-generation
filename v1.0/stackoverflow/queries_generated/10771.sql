-- Performance Benchmarking Query

-- This query retrieves the following statistics:
-- 1. Count of posts by type
-- 2. Average score of posts by type
-- 3. Total number of comments made on posts
-- 4. Count of users who have made at least one post

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(DISTINCT OwnerUserId) FROM Posts) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
