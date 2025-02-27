-- Performance benchmarking query to analyze posts and their associated data
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) AS tag_name ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_name
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC;
