
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
LEFT JOIN 
    Comments c ON u.Id = c.UserId AND c.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
LEFT JOIN 
    Votes v ON u.Id = v.UserId AND v.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= DATEADD(year, -1, '2024-10-01 12:34:56')
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;
