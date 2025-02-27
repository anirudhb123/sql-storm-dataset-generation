
SELECT 
    u.DisplayName AS UserName, 
    p.Title AS PostTitle, 
    COUNT(c.Id) AS CommentCount, 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    MAX(b.Date) AS LastBadgeDate
FROM 
    Users u 
JOIN 
    Posts p ON u.Id = p.OwnerUserId 
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
LEFT JOIN 
    Badges b ON u.Id = b.UserId 
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year' 
    AND p.PostTypeId = 1 
    AND p.Score > 0 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    u.Id, 
    p.Id 
ORDER BY 
    UpVotes DESC, 
    CommentCount DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
