WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.OwnerUserId,
        a.Title,
        a.CreationDate,
        r.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    INNER JOIN 
        RecursiveCTE r ON q.Id = r.PostId
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
    COUNT(DISTINCT p.Id) AS AnswerCount,
    COUNT(DISTINCT p1.Id) AS QuestionCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MIN(p.CreationDate) AS FirstPostDate,
    MAX(p.LastActivityDate) AS LastPostDate,
    LEAD(MAX(p.LastActivityDate)) OVER (PARTITION BY u.Id ORDER BY MAX(p.LastActivityDate)) AS NextActivityDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
LEFT JOIN 
    RecursiveCTE r ON r.OwnerUserId = u.Id
LEFT JOIN 
    Posts p1 ON p1.OwnerUserId = u.Id AND p1.PostTypeId = 1 -- for counting questions
WHERE 
    u.Reputation > 100  -- User must have a reputation higher than 100
    AND (p.CreationDate IS NOT NULL OR p.LastActivityDate IS NOT NULL)
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5  -- At least 5 answers
    AND MAX(p.LastActivityDate) >= NOW() - INTERVAL '6 months'  -- Active within the last 6 months
ORDER BY 
    u.Reputation DESC
LIMIT 
    10;
