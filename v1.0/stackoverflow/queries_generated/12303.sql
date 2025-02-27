-- Performance Benchmarking Query

-- This query retrieves the number of posts, average scores, and the total votes for each post type.
-- It joins Posts with PostTypes and Votes to gather the necessary data.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS NumberOfPosts,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    NumberOfPosts DESC;
