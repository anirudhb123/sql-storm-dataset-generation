
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    t.TagName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
        (SELECT @row := @row + 1 AS n
         FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 
             UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers, 
            (SELECT @row := 0) r) numbers
     WHERE 
         @row < LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS t ON TRUE
WHERE 
    p.CreationDate >= NOW() - INTERVAL 1 YEAR 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
