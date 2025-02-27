
SELECT 
    Users.DisplayName,
    Posts.Title,
    Posts.CreationDate,
    Posts.ViewCount,
    Posts.Score
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
WHERE 
    Posts.PostTypeId = 1  
ORDER BY 
    Posts.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
