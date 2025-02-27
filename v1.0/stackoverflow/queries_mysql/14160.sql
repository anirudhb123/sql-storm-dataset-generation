
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    DATE_FORMAT(u.CreationDate, '%Y-%m-01') AS UserCreationMonth,
    YEAR(u.CreationDate) AS CreationYear
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName, DATE_FORMAT(u.CreationDate, '%Y-%m-01'), YEAR(u.CreationDate)
ORDER BY 
    UserCreationMonth, u.DisplayName;
