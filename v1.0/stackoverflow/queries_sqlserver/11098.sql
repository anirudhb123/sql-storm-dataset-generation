
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounty,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
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
OUTER APPLY 
    (SELECT value AS tag_name FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS tag_name
LEFT JOIN 
    Tags t ON tag_name.value = t.TagName
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 month' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, u.Reputation, ph.CreationDate
ORDER BY 
    p.CreationDate DESC;
