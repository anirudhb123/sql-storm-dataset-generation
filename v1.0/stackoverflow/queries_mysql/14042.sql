
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
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
LEFT JOIN 
    (SELECT DISTINCT t.TagName, p.Id FROM Tags t JOIN Posts p ON FIND_IN_SET(t.TagName, REPLACE(REPLACE(p.Tags, '><', ','), '>', '')))) AS tag ON p.Id = tag.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL 1 YEAR
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
