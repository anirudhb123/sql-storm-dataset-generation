SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    UNNEST(string_to_array(p.Tags, '<>')) AS tag_id ON t.Id = tag_id
LEFT JOIN 
    Tags t ON tag_id = t.TagName
WHERE 
    p.PostTypeId = 1 -- Questions only
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.CreationDate DESC;
