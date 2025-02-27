
SELECT 
    Users.DisplayName, 
    Posts.Title, 
    Posts.CreationDate, 
    Posts.Score 
FROM 
    Posts 
INNER JOIN 
    Users ON Posts.OwnerUserId = Users.Id 
WHERE 
    Posts.PostTypeId = 1 
GROUP BY 
    Users.DisplayName, 
    Posts.Title, 
    Posts.CreationDate, 
    Posts.Score 
ORDER BY 
    Posts.CreationDate DESC 
LIMIT 10;
