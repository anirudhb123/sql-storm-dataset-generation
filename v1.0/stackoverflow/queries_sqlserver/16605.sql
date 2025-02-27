
SELECT 
    Posts.Id AS PostId,
    Posts.Title,
    Posts.CreationDate,
    Users.DisplayName AS Author,
    Posts.Score,
    Posts.ViewCount
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
WHERE 
    Posts.PostTypeId = 1
GROUP BY 
    Posts.Id,
    Posts.Title,
    Posts.CreationDate,
    Users.DisplayName,
    Posts.Score,
    Posts.ViewCount
ORDER BY 
    Posts.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
