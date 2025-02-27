-- Performance Benchmarking Query

-- This query retrieves the total number of posts, the average score of questions, and the number of users with badges,
-- aggregated by the year of creation, to observe performance on multiple aggregations.
SELECT 
    EXTRACT(YEAR FROM p.CreationDate) AS Year,
    COUNT(p.Id) AS TotalPosts,
    AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AverageQuestionScore,
    COUNT(DISTINCT b.UserId) AS TotalUsersWithBadges
FROM 
    Posts p
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    Year
ORDER BY 
    Year DESC;
