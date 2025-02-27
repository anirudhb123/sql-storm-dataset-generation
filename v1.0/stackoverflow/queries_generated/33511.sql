WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionDate,
    COUNT(a.Id) AS AnswerCount,
    AVG(a.Score) AS AvgAnswerScore,
    COUNT(c.Id) AS CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ph.Level AS QuestionHierarchyLevel
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Answers
LEFT JOIN 
    Comments c ON c.PostId = p.Id -- Comments
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ', ') t ON TRUE -- string manipulation for tags
LEFT JOIN 
    RecursivePostHierarchy ph ON ph.PostId = p.Id
WHERE 
    u.Reputation > 1000 -- Users with high reputation
GROUP BY 
    u.DisplayName, u.Reputation, p.Title, p.CreationDate, ph.Level
HAVING 
    COUNT(a.Id) > 0 -- Only include questions with at least one answer
ORDER BY 
    AvgAnswerScore DESC
LIMIT 50;
