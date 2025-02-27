
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
    SUM(b.Class) AS TotalBadges,
    COUNT(DISTINCT c.Id) AS TotalComments,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
         p.Id, 
         value AS TagName 
     FROM 
         Posts p 
     CROSS APPLY STRING_SPLIT(p.Tags, ',')) t ON p.Id = t.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName, u.Id
ORDER BY 
    TotalPosts DESC, AverageScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
