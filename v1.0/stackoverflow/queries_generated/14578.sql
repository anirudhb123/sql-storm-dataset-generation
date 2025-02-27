-- Performance benchmarking query to analyze user engagement with posts and their associated comments
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.Score) AS TotalScore,
    AVG(p.CreationDate) AS AvgPostCreationDate,
    AVG(c.CreationDate) AS AvgCommentCreationDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC, TotalComments DESC;
