SELECT 
    Users.DisplayName,
    COUNT(Posts.Id) AS PostCount,
    SUM(Votes.VoteTypeId = 2) AS UpVotes,
    SUM(Votes.VoteTypeId = 3) AS DownVotes
FROM 
    Users
LEFT JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
LEFT JOIN 
    Votes ON Posts.Id = Votes.PostId
GROUP BY 
    Users.Id
ORDER BY 
    PostCount DESC
LIMIT 10;
