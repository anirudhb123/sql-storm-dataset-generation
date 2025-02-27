
SELECT 
    Posts.Id AS PostId,
    Posts.Title,
    Posts.CreationDate,
    Users.DisplayName AS OwnerDisplayName,
    COUNT(Comments.Id) AS CommentCount,
    SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
LEFT JOIN 
    Comments ON Posts.Id = Comments.PostId
LEFT JOIN 
    Votes ON Posts.Id = Votes.PostId
WHERE 
    Posts.PostTypeId = 1 
GROUP BY 
    Posts.Id, Posts.Title, Posts.CreationDate, Users.DisplayName
ORDER BY 
    Posts.CreationDate DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;
