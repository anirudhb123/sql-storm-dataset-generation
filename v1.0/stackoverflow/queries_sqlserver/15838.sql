
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
    Tags ON Posts.Tags LIKE '%' + Tags.TagName + '%'
WHERE 
    Posts.PostTypeId = 1 
GROUP BY 
    Users.DisplayName,
    Posts.Title,
    Posts.CreationDate,
    Posts.Score,
    Tags.TagName
ORDER BY 
    Posts.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
