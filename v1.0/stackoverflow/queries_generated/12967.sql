-- Performance benchmarking query for the Stack Overflow schema

-- This query fetches detailed information about posts along with user statistics,
-- and aggregates the number of votes and comments for each post to benchmark
-- performance regarding querying and analyzing data.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownVotes,
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
    VoteTypes vt ON v.VoteTypeId = vt.Id
LEFT JOIN 
    unnest(string_to_array(p.Tags, '>')) AS tag ON tag IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Consider posts from the last year
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.ViewCount DESC
LIMIT 100;  -- Limit results to top 100 posts by view count
