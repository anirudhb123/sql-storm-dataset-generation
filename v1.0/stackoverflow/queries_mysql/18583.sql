
SELECT 
    Posts.Title, 
    Users.DisplayName as OwnerDisplayName, 
    Posts.CreationDate, 
    Posts.Score, 
    Posts.ViewCount 
FROM 
    Posts 
JOIN 
    Users ON Posts.OwnerUserId = Users.Id 
WHERE 
    Posts.PostTypeId = 1 
GROUP BY 
    Posts.Title, 
    Users.DisplayName, 
    Posts.CreationDate, 
    Posts.Score, 
    Posts.ViewCount
ORDER BY 
    Posts.CreationDate DESC 
LIMIT 10;
