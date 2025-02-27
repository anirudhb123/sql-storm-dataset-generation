WITH RECURSIVE AnswerChain AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AcceptedAnswerId,
        0 AS Level,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        ac.Level + 1,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        AnswerChain ac ON p.ParentId = ac.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT a.PostId) AS TotalQuestions,
    COUNT(DISTINCT ac.PostId) AS TotalAnswers,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentScores,
    AVG(COALESCE(DATEDIFF(NOW(), a.CreationDate), 0)) AS AvgDaysToAnswer,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    Posts a ON a.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.UserId = u.Id
LEFT JOIN 
    AnswerChain ac ON ac.OwnerUserId = u.Id
LEFT JOIN 
    UNNEST(SPLIT(a.Tags, ',')) AS t(TagName)
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalQuestions DESC, TotalCommentScores DESC
LIMIT 50;

-- Performance benchmarking
EXPLAIN ANALYZE 
WITH RECURSIVE AnswerChain AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AcceptedAnswerId,
        0 AS Level,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions
 
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        ac.Level + 1,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        AnswerChain ac ON p.ParentId = ac.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT a.PostId) AS TotalQuestions,
    COUNT(DISTINCT ac.PostId) AS TotalAnswers,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentScores,
    AVG(COALESCE(DATEDIFF(NOW(), a.CreationDate), 0)) AS AvgDaysToAnswer,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    Posts a ON a.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.UserId = u.Id
LEFT JOIN 
    AnswerChain ac ON ac.OwnerUserId = u.Id
LEFT JOIN 
    UNNEST(SPLIT(a.Tags, ',')) AS t(TagName)
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalQuestions DESC, TotalCommentScores DESC
LIMIT 50;
