-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(v.UpVotes, 0) AS UpVoteCount,
    COALESCE(v.DownVotes, 0) AS DownVoteCount,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId IN (1, 2) -- Only Questions and Answers
GROUP BY 
    p.Id, u.DisplayName, v.UpVotes, v.DownVotes
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit number of rows for benchmarking purposes
