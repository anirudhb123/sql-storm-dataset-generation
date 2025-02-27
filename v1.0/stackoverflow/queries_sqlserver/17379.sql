
SELECT 
    Posts.Title,
    Users.DisplayName,
    Posts.CreationDate,
    Posts.Score,
    Posts.ViewCount,
    COUNT(Comments.Id) AS CommentCount
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
LEFT JOIN 
    Comments ON Posts.Id = Comments.PostId
WHERE 
    Posts.PostTypeId = 1  
GROUP BY 
    Posts.Title, Users.DisplayName, Posts.CreationDate, Posts.Score, Posts.ViewCount
ORDER BY 
    Posts.Score DESC, Posts.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
