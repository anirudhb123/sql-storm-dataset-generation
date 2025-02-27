
SELECT 
    Users.DisplayName,
    Users.Reputation,
    Posts.Title,
    Posts.CreationDate,
    Posts.ViewCount
FROM 
    Users
JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
WHERE 
    Posts.PostTypeId = 1
GROUP BY 
    Users.DisplayName,
    Users.Reputation,
    Posts.Title,
    Posts.CreationDate,
    Posts.ViewCount
ORDER BY 
    Posts.ViewCount DESC
LIMIT 10;
