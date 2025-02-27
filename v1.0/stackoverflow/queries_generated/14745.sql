-- Performance benchmarking query to analyze user engagement and post activity
SELECT 
    u.Id AS UserId, 
    u.DisplayName, 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(c.Score) AS TotalCommentScore,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,
    SUM(v.VoteTypeId = 3) AS TotalDownVotes,
    AVG(DATEDIFF(NOW(), p.CreationDate)) AS AvgPostAgeInDays
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;
