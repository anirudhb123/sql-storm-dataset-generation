SELECT 
    Posts.Id AS PostId,
    Posts.Title,
    Users.DisplayName AS OwnerDisplayName,
    Posts.CreationDate,
    Posts.Score,
    Posts.ViewCount
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
WHERE 
    Posts.PostTypeId = 1 -- Filtering for questions only
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10; -- Fetching the 10 most recent questions
