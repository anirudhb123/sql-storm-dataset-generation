-- Performance Benchmarking Query for Stack Overflow Schema

-- This query will retrieve all posts with their respective user information, tags, and votes to analyze the performance of the system

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    t.TagName,
    v.VoteTypeId,
    COUNT(c.Id) AS CommentCount,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.FavoriteCount,
    PH.Comment AS PostHistoryComment
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    PostHistory PH ON PH.PostId = p.Id
WHERE 
    p.CreationDate >= '2023-01-01' -- Adjust the date as needed for performance testing
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, t.TagName, v.VoteTypeId, PH.Comment
ORDER BY 
    p.CreationDate DESC 
LIMIT 100; -- Adjust the limit as needed for performance benchmarking
