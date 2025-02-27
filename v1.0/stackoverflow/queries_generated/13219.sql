-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves a summary of posts along with user information and their corresponding tags
-- It aims to evaluate performance by joining multiple tables and aggregating results

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.AnswerCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ARRAY_AGG(t.TagName) AS Tags,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount

FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9)

GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
