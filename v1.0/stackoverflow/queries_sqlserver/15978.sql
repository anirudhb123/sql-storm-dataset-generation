
SELECT 
    Posts.Title, 
    Users.DisplayName AS Author, 
    Posts.CreationDate, 
    Posts.Score, 
    Posts.ViewCount 
FROM 
    Posts 
JOIN 
    Users ON Posts.OwnerUserId = Users.Id 
WHERE 
    Posts.PostTypeId = 1 
ORDER BY 
    Posts.CreationDate DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
