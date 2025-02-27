-- Performance Benchmarking Query for Stack Overflow Schema

-- This query intends to benchmark the performance when joining multiple tables
-- and aggregating data for analytics, focusing on posts, their associated users,
-- and how they are tagged, as well as any comments and votes associated with them.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    UNNEST(string_to_array(p.Tags, ',')) AS tag_name ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(BOTH ' ' FROM tag_name)
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC;
