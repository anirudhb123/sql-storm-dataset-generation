-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    p.AnswerCount,
    p.CommentCount,
    ph.UserDisplayName AS LastEditorDisplayName,
    ph.CreationDate AS LastEditDate,
    pt.Name AS PostType,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.LastEditorUserId = ph.UserId AND p.Id = ph.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_array
LEFT JOIN 
    Tags t ON t.TagName = tag_array 
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, CURRENT_TIMESTAMP) -- Posts created in the last year
GROUP BY 
    p.Id, u.DisplayName, ph.UserDisplayName, ph.CreationDate, pt.Name
ORDER BY 
    p.ViewCount DESC -- Order by number of views
LIMIT 100; -- Limit to top 100 posts
