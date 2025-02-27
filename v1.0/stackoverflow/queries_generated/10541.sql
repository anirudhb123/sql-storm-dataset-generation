-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the top 10 users based on their total reputation,
-- along with the count of their posts, answers, and comments.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts a ON a.AcceptedAnswerId = p.Id
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- This query evaluates the average score of questions and answers
-- along with the total number of answers per question.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score AS PostScore,
    COUNT(a.Id) AS AnswerCount,
    AVG(a.Score) AS AverageAnswerScore
FROM 
    Posts p
LEFT JOIN 
    Posts a ON a.ParentId = p.Id
WHERE 
    p.PostTypeId = 1  -- Considering only questions
GROUP BY 
    p.Id, p.Title, p.Score
ORDER BY 
    PostScore DESC
LIMIT 10;

-- This query checks the average view count of posts by type

SELECT 
    pt.Name AS PostType,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageViewCount DESC;
