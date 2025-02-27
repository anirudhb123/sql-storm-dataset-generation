SELECT 
    Users.Id AS UserId,
    Users.DisplayName,
    Posts.Title,
    Posts.CreationDate,
    Posts.Score
FROM 
    Users
JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
WHERE 
    Posts.PostTypeId = 1  -- Filtering for questions
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;  -- Limit to the most recent 10 questions
