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
    Posts.PostTypeId = 1  -- Filtering for Questions only
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;  -- Get the latest 10 questions
