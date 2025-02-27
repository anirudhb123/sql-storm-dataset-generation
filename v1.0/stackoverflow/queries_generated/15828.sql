SELECT 
    Posts.Title, 
    Posts.CreationDate, 
    Users.DisplayName, 
    Posts.Score, 
    Posts.ViewCount 
FROM 
    Posts 
JOIN 
    Users ON Posts.OwnerUserId = Users.Id 
WHERE 
    Posts.PostTypeId = 1 -- Filter for Questions 
ORDER BY 
    Posts.CreationDate DESC 
LIMIT 10;
