-- Performance benchmarking SQL query for StackOverflow schema

-- This query retrieves the number of questions, average score, 
-- and total views for each user, ordering by total views.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS QuestionCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalViews DESC;
