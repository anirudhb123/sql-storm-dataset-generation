SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes,
    pt.Name AS PostType,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') AS tagList ON tagList.value IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tagList.value)
GROUP BY 
    p.Id, u.DisplayName, pt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
