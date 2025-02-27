SELECT 
    Users.DisplayName, 
    COUNT(Posts.Id) AS NumberOfPosts, 
    SUM(Votes.VoteTypeId = 2) AS UpVotesCount, 
    SUM(Votes.VoteTypeId = 3) AS DownVotesCount 
FROM 
    Users 
LEFT JOIN 
    Posts ON Users.Id = Posts.OwnerUserId 
LEFT JOIN 
    Votes ON Posts.Id = Votes.PostId 
GROUP BY 
    Users.DisplayName 
ORDER BY 
    NumberOfPosts DESC;
