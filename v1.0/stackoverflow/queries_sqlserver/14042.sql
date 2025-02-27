
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
    CASE 
        WHEN p.PostTypeId = 1 THEN 'Question'
        WHEN p.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
OUTER APPLY 
    (SELECT value FROM STRING_SPLIT(p.Tags, '><')) AS tag 
LEFT JOIN 
    Tags t ON tag.value = t.TagName
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
