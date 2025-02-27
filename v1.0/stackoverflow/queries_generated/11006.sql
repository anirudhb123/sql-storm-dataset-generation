-- Performance Benchmarking SQL Query

-- This query retrieves the average score of questions, the count of answers per question,
-- and the total number of votes associated with each user,
-- grouped by user reputation and ordered by reputation.

SELECT 
    u.Reputation AS UserReputation,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    AVG(p.Score) AS AverageQuestionScore,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,
    SUM(v.VoteTypeId = 3) AS TotalDownVotes,
    COUNT(a.Id) AS AnswerCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts a ON a.ParentId = p.Id -- Join to get answers related to the questions
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    p.PostTypeId = 1 -- Only considering questions
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;
