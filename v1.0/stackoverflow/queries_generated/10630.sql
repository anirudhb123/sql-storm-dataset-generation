-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName,
    STRING_AGG(t.TagName, ', ') AS Tags,
    ph.CreationDate AS LastEditDate,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[]) -- Assuming Tags are stored as comma-separated IDs
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 4 -- Last Edit Title
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Filter for Questions
GROUP BY 
    p.Id, u.Id, ph.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit results for benchmarking
