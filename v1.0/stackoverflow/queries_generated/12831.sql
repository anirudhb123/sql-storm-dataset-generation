-- Performance benchmarking query to retrieve the number of posts, total votes, and average score per user

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes,  -- UpMod votes
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownVotes, -- DownMod votes
    COALESCE(SUM(p.Score), 0) AS TotalScore,
    COALESCE(AVG(p.Score), 0) AS AverageScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, AverageScore DESC;
