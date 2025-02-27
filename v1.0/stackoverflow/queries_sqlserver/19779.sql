
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Users AS u
JOIN 
    Posts AS p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments AS c ON p.Id = c.PostId
LEFT JOIN 
    Votes AS v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate
ORDER BY 
    VoteCount DESC, CommentCount DESC;
