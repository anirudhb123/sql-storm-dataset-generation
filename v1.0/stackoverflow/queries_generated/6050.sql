SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(u.Reputation) AS AvgReputation,
    SUM(b.Class = 1) AS TotalGoldBadges,
    SUM(b.Class = 2) AS TotalSilverBadges,
    SUM(b.Class = 3) AS TotalBronzeBadges,
    COUNT(DISTINCT ph.Id) AS TotalPostHistoryEntries
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    u.CreationDate >= '2020-01-01'
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    AvgReputation DESC, TotalPosts DESC;
