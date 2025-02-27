SELECT 
    Users.DisplayName, 
    Posts.Title, 
    Posts.CreationDate, 
    Posts.Score 
FROM 
    Posts 
JOIN 
    Users ON Posts.OwnerUserId = Users.Id 
WHERE 
    Posts.PostTypeId = 1 -- We're only interested in Questions
ORDER BY 
    Posts.CreationDate DESC 
LIMIT 10;
