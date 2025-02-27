-- Performance benchmarking query to analyze post activity and user contributions
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS TotalWikis,
    SUM(c.CommentCount) AS TotalComments,
    SUM(v.BountyAmount) AS TotalBounties,
    SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
    COUNT(DISTINCT t.Id) AS TotalTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    unnest(string_to_array(p.Tags, ', ')) AS t(TagName) ON true
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;
