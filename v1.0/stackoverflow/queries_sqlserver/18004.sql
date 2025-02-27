
SELECT 
    Users.DisplayName, 
    Posts.Title, 
    Posts.CreationDate, 
    Votes.VoteTypeId
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
LEFT JOIN 
    Votes ON Posts.Id = Votes.PostId
WHERE 
    Posts.PostTypeId = 1 
GROUP BY 
    Users.DisplayName, 
    Posts.Title, 
    Posts.CreationDate, 
    Votes.VoteTypeId
ORDER BY 
    Posts.CreationDate DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
