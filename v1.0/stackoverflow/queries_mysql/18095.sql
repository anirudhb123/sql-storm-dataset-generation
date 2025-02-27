
SELECT 
    Posts.Title, 
    Posts.CreationDate, 
    Users.DisplayName AS OwnerDisplayName, 
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
    Posts.CreationDate, 
    Users.DisplayName, 
    Posts.Score, 
    Posts.ViewCount 
ORDER BY 
    Posts.CreationDate DESC 
LIMIT 10;
