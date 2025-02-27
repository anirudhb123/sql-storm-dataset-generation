-- Performance benchmarking query to analyze posts and their associated data
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    ph.RevisionGUID,
    ph.CreationDate AS HistoryCreationDate,
    ph.Comment AS HistoryComment
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) AS tag(tagname)
LEFT JOIN 
    Tags t ON tag.tagname = t.TagName
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
GROUP BY 
    p.Id, u.DisplayName, ph.RevisionGUID
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit results for performance testing
