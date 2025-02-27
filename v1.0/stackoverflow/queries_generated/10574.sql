-- Performance Benchmarking Query

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    pt.Name AS PostTypeName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount,
    SUM(v.VoteTypeId = 3) AS DownVoteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName, u.Reputation, pt.Name
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
