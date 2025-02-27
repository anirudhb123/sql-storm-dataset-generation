-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the number of posts by post type along with the total score and average score per post type
-- It also includes a count of users and the average reputation of users who created these posts

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(p.Score) AS TotalScore,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT u.Id) AS UserCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
