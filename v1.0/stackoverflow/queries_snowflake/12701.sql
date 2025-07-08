
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    LISTAGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT p.Id, tag_id FROM Posts p, 
                    LATERAL SPLIT_TO_TABLE(p.Tags, '<>') AS tag_id) AS tag_id ON p.Id = tag_id.Id
LEFT JOIN 
    Tags t ON tag_id.tag_id = t.TagName
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
ORDER BY 
    p.CreationDate DESC;
