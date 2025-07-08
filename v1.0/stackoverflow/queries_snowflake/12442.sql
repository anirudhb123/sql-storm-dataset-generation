
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    (SELECT COUNT(*) 
     FROM Posts AS a 
     WHERE a.ParentId = p.Id) AS AnswerCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN LATERAL 
    (SELECT 
        TRIM(value) AS TagName 
     FROM TABLE(FLATTEN(input => SPLIT(p.Tags, '><'))) 
    ) t ON TRUE
WHERE p.PostTypeId = 1 
GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY p.CreationDate DESC
LIMIT 100;
