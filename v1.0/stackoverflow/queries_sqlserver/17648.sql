
SELECT 
    U.DisplayName AS UserDisplayName,
    Post.Title AS PostTitle,
    Post.CreationDate AS PostCreationDate,
    Post.Body AS PostBody,
    COUNT(C.CommentId) AS CommentCount
FROM 
    Posts AS Post
JOIN 
    Users AS U ON Post.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT 
         Id AS CommentId, 
         PostId 
     FROM 
         Comments) AS C ON Post.Id = C.PostId
WHERE 
    Post.PostTypeId = 1 
GROUP BY 
    U.DisplayName, Post.Title, Post.CreationDate, Post.Body
ORDER BY 
    Post.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
