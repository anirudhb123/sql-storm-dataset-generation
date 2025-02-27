
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ph.CreationDate AS HistoryCreationDate,
    ph.Comment AS HistoryComment,
    ph.PostHistoryTypeId,
    ph.Text AS HistoryText
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId IN (1, 2) 
GROUP BY 
    p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName, u.Reputation, ph.CreationDate, ph.Comment, ph.PostHistoryTypeId, ph.Text
ORDER BY 
    p.Score DESC
LIMIT 10;
