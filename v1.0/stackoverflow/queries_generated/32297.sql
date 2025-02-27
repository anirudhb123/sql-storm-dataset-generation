WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    JOIN 
        Posts a ON p.ParentId = a.Id  -- Join to find answers
    WHERE 
        a.PostTypeId = 1
)
SELECT 
    u.DisplayName AS Author,
    p.Title,
    r.Score AS QuestionScore,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    COALESCE(NULLIF(p.Body, ''), 'No Content') AS PostBody,
    COUNT(DISTINCT r.PostId) AS AnswerCount,
    MIN(r.CreationDate) AS FirstAnswerDate,
    MAX(r.CreationDate) AS LastActivityDate
FROM 
    Posts p
LEFT JOIN 
    RecursivePostCTE r ON p.Id = r.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1  -- Only Questions
GROUP BY 
    u.Id, p.Title, r.Score
HAVING 
    COUNT(c.Id) > 0 AND 
    SUM(v.VoteTypeId = 2) > SUM(v.VoteTypeId = 3)  -- Only Questions with more upvotes than downvotes
ORDER BY 
    QuestionScore DESC, AnswerCount DESC
LIMIT 100;
