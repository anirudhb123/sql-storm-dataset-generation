-- Performance Benchmarking Query for StackOverflow Schema

-- This query benchmarks the join performance and aggregations across multiple tables

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000  -- Filtering users with reputation greater than 1000
GROUP BY 
    u.Id, u.DisplayName 
ORDER BY 
    PostCount DESC
LIMIT 100;  -- Limiting the output for benchmarking performance
