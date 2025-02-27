SELECT 
    Users.DisplayName, 
    Posts.Title, 
    Posts.CreationDate, 
    Posts.Score, 
    Tags.TagName
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
JOIN 
    Tags ON Posts.Tags LIKE '%' || Tags.TagName || '%'
WHERE 
    Posts.PostTypeId = 1 -- Select only questions
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;
