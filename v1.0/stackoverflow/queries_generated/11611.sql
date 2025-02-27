-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the average score and view count of questions along with the count of answers
-- It also joins with Users to include the reputation of the post owners

SELECT 
    p.Title,
    u.Reputation AS OwnerReputation,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(a.Id) AS AnswerCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
WHERE 
    p.PostTypeId = 1  -- Only for questions
GROUP BY 
    p.Id, u.Reputation, p.Title
ORDER BY 
    AverageScore DESC
LIMIT 100;  -- Limiting to top 100 questions by average score
