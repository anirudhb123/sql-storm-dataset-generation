-- Performance Benchmarking Query
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS AuthorName,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpVotes,
    AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AverageDownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- filter for posts created in 2023
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit the output for performance benchmarking
