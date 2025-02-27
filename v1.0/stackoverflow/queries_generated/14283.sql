-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
    p.AnswerCount,
    p.CommentCount,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    pt.Name AS PostType,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Posts a ON p.AcceptedAnswerId = a.Id
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') AS t ON t.value IS NOT NULL
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, a.AcceptedAnswerId, 
    p.AnswerCount, p.CommentCount, u.Reputation, pt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
