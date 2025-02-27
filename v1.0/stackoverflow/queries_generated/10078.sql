-- Performance benchmarking query to analyze posts, their scores, and user engagement
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    COUNT(h.Id) AS HistoryCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory h ON p.Id = h.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for the last year
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.Score DESC;
