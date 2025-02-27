-- Performance benchmarking query to analyze posts and user interactions on Stack Overflow

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
    ph.PostHistoryTypeId,
    ph.CreationDate AS PostHistoryDate,
    COUNT(c.Id) AS CommentCountTotal,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2020-01-01' AND p.CreationDate < '2023-01-01'  -- Filter for a specific date range
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, ph.PostHistoryTypeId, ph.CreationDate
ORDER BY 
    p.CreationDate DESC;
