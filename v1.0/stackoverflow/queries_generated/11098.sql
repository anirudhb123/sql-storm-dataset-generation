-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounty,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ph.CreationDate AS LastHistoryUpdate
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
    UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON TRUE
LEFT JOIN 
    Tags t ON tag_name = t.TagName
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 month' -- Filter for posts created in the last month
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, ph.CreationDate
ORDER BY 
    p.CreationDate DESC;
