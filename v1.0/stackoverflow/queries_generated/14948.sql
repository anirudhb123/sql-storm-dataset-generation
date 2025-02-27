-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the average score, view count, and answer count 
-- for each post type along with the total number of posts in each type.
-- Additionally, it collects the most recent activity date and creation date 
-- for performance metrics. 

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.AnswerCount) AS AverageAnswerCount,
    MAX(p.LastActivityDate) AS MostRecentActivity,
    AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AverageTimeToActivity -- average time from post creation to last activity in seconds
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
