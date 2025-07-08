
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    p.ViewCount,
    p.Score,
    t.TagName
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT 
        p.Id, 
        TRIM(REGEXP_SUBSTR(p.Tags, '[^><]+', 1, seq)) AS TagName
     FROM 
        Posts p,
        TABLE(GENERATOR(ROWCOUNT => 100)) AS seq
     WHERE 
        seq <= REGEXP_COUNT(p.Tags, '><') + 1) t ON p.Id = t.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.Score, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
