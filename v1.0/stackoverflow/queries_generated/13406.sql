-- Performance Benchmarking Query

-- This query retrieves data related to the most popular posts 
-- including their title, view count, score, number of answers, and the user who created them.
-- It also collects information about comments associated with each post.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1  -- Only considering Questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.ViewCount DESC, p.Score DESC
LIMIT 100;  -- Limiting the results to the top 100 posts
