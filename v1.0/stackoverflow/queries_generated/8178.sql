SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
    AVG(p.Score) AS AverageScore,
    SUM(b.Class = 1) AS GoldBadges,
    SUM(b.Class = 2) AS SilverBadges,
    SUM(b.Class = 3) AS BronzeBadges,
    COUNT(DISTINCT ph.Id) AS TotalPostHistoryChanges,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
FROM 
    Users u 
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId 
LEFT JOIN 
    Badges b ON u.Id = b.UserId 
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId 
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
WHERE 
    u.Reputation > 1000 
GROUP BY 
    u.DisplayName 
ORDER BY 
    TotalPosts DESC 
LIMIT 10;
