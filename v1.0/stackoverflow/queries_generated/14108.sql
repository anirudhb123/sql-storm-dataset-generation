-- Performance Benchmarking Query Example
-- This query retrieves posts along with associated user details and post history information for performance analysis

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ph.CreationDate AS HistoryCreationDate,
    pht.Name AS HistoryTypeName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Limit to posts created in the last 30 days
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, ph.CreationDate, pht.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit the result to the latest 100 posts
