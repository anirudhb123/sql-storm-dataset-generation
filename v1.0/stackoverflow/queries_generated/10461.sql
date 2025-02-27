-- Performance benchmarking query to evaluate the average score of questions by user reputation
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    AVG(p.Score) AS AverageQuestionScore,
    COUNT(p.Id) AS TotalQuestions
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1 -- Only consider questions
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    AverageQuestionScore DESC
LIMIT 10; -- Retrieve top 10 users by average question score
