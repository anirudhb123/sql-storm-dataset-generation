SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,
    SUM(v.VoteTypeId = 3) AS TotalDownVotes,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    AVG(DATEDIFF(second, p.CreationDate, p.LastActivityDate)) AS AvgPostDurationInSeconds
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    u.Reputation > 1000 -- Filtering users with high reputation
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;
