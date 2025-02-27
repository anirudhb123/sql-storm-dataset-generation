-- Performance Benchmarking Query for Stack Overflow Schema

-- Retrieving a summary of posts, their types, and user engagement metrics
SELECT 
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,  -- UpMod
    SUM(v.VoteTypeId = 3) AS DownVotes, -- DownMod
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount,
    p.Score,
    p.FavoriteCount,
    p.AnswerCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Consider posts created in the last year
GROUP BY 
    p.Id, pt.Name, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
