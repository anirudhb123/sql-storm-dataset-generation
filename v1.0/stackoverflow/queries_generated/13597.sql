-- Performance benchmarking query to retrieve post statistics, user reputation, and related tags
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
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, '<>') AS tag_names ON p.Tags IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag_names
WHERE 
    p.PostTypeId = 1  -- Only questions
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC, p.Score DESC;
