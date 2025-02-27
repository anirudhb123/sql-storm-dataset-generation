-- Query to benchmark performance by retrieving key statistics from multiple tables in the StackOverflow schema

SELECT 
    COUNT(DISTINCT u.Id) AS TotalUsers,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    COUNT(DISTINCT ph.Id) AS TotalPostHistory,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(u.Reputation) AS AverageUserReputation,
    AVG(p.Score) AS AveragePostScore,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year';  -- Filter for posts created in the last year
