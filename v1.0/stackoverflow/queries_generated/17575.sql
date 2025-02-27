SELECT 
    Posts.Id AS PostId,
    Posts.Title,
    Users.DisplayName AS OwnerDisplayName,
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
    Posts.PostTypeId = 1  -- Only questions
GROUP BY 
    Posts.Id, Users.DisplayName
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;  -- Limit to the latest 10 questions
