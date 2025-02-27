
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ',') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_name
     FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
           UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
     WHERE numbers.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag_name 
ON tag_name IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag_name
WHERE 
    p.PostTypeId IN (1, 2)  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, 
    u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
