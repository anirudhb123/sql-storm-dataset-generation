
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author,
    COUNT(v.Id) AS VoteCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    pt.Name AS PostType,
    COALESCE(ROUND(AVG(u.Reputation), 2), 0) AS AvgAuthorReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= DATEADD(DAY, -30, '2024-10-01')
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, pt.Name
ORDER BY 
    VoteCount DESC, p.CreationDate DESC;
