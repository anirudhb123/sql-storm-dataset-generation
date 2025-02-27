-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount,
    SUM(v.VoteTypeId = 3) AS DownVoteCount,
    p.ViewCount,
    p.Score,
    p.AnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Filter for the last 30 days
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
