
SELECT 
    Posts.Id AS PostId,
    Posts.Title,
    Posts.CreationDate,
    Users.DisplayName AS OwnerDisplayName,
    Users.Reputation
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
WHERE 
    Posts.PostTypeId = 1 
GROUP BY 
    Posts.Id, Posts.Title, Posts.CreationDate, Users.DisplayName, Users.Reputation
ORDER BY 
    Posts.CreationDate DESC
LIMIT 10;
