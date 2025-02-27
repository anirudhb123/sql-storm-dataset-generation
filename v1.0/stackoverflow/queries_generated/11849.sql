-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT STRING_AGG(tag.TagName, ', ') FROM Tags tag WHERE tag.Id IN (SELECT UNNEST(string_to_array(p.Tags, '>'))::int)) AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 1000;
