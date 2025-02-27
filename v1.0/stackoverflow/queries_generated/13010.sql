-- Performance Benchmarking Query for Stack Overflow Schema

-- 1. Retrieve the count of posts based on post types
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- 2. Average score for questions and their related answers
SELECT 
    q.Title AS QuestionTitle, 
    AVG(a.Score) AS AverageAnswerScore
FROM 
    Posts q
LEFT JOIN 
    Posts a ON q.Id = a.ParentId
WHERE 
    q.PostTypeId = 1 -- Questions
GROUP BY 
    q.Title
ORDER BY 
    AverageAnswerScore DESC;

-- 3. User reputation vs number of questions posted
SELECT 
    u.DisplayName, 
    u.Reputation, 
    COUNT(q.Id) AS NumberOfQuestions
FROM 
    Users u
LEFT JOIN 
    Posts q ON u.Id = q.OwnerUserId AND q.PostTypeId = 1 -- Questions
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    NumberOfQuestions DESC, u.Reputation DESC;

-- 4. Most common close reasons and their counts
SELECT 
    cr.Name AS CloseReason, 
    COUNT(ph.Id) AS CloseReasonCount
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes cr ON ph.Comment::int = cr.Id
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen actions
GROUP BY 
    cr.Name
ORDER BY 
    CloseReasonCount DESC;

-- 5. Execution time analysis of commonly performed queries
EXPLAIN ANALYZE
SELECT 
    p.Title, 
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    CommentCount DESC
LIMIT 10;
