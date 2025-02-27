
SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS AuthorName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, p.CreationDate, u.DisplayName
ORDER BY 
    PostCreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
