-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount,
    SUM(v.VoteTypeId = 3) AS DownVoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    u.DisplayName AS OwnerDisplayName,
    -- Benchmarking the time taken to execute the grouped operations
    EXTRACT(EPOCH FROM NOW()) AS BenchmarkStartTime
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    LATERAL unnest(string_to_array(p.Tags, '>')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit the number of results for benchmarking purposes
