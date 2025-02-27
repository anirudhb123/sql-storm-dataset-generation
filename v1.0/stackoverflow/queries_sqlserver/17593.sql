
SELECT 
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.Score,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts AS p
JOIN 
    Users AS u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments AS c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.Score
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
