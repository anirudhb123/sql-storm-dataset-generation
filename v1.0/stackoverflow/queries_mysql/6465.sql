
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    CASE WHEN ph.PostId IS NOT NULL THEN 'Closed' ELSE 'Open' END AS PostStatus,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
    MAX(p.LastActivityDate) AS LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag_name
     FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 
           UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_name ON true
LEFT JOIN 
    Tags t ON t.TagName = tag_name
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, ph.PostId
ORDER BY 
    LastActivityDate DESC
LIMIT 
    50;
