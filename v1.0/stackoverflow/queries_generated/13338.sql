-- Performance benchmarking SQL query for Stack Overflow schema

-- This query fetches the top 10 users based on the number of questions along with their reputation,
-- who have accepted answers associated with their questions. It also counts the total number of answers received.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COUNT(DISTINCT a.Id) AS TotalAcceptedAnswers,
    SUM(p.AnswerCount) AS TotalAnswersReceived
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts a ON p.AcceptedAnswerId = a.Id -- Accepted Answers
WHERE 
    u.Reputation > 0
GROUP BY 
    u.Id
ORDER BY 
    TotalQuestions DESC
LIMIT 10;

