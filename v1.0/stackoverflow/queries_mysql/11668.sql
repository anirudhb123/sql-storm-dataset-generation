
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
    ph.RevisionGUID,
    ph.CreationDate AS HistoryCreationDate,
    ph.Comment AS HistoryComment
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
LEFT JOIN 
    (SELECT id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS tagname
     FROM 
         (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
          UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
     WHERE 
         CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag 
ON 
    TRUE
LEFT JOIN 
    Tags t ON tag.tagname = t.TagName
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
    u.DisplayName, ph.RevisionGUID, ph.CreationDate, ph.Comment
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
