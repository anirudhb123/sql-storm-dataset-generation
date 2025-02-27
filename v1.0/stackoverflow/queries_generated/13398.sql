-- Performance Benchmarking Query
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    AVG(ph.CreationDate) AS AvgRevisionDate
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
    Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
WHERE
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY
    p.Id, u.DisplayName
ORDER BY
    p.CreationDate DESC
LIMIT 100;
