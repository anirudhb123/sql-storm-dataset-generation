-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves user statistics and post information,
-- joining multiple tables to measure query execution time and performance.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    MAX(p.CreationDate) AS LastPostDate,
    COUNT(c.Id) AS TotalComments,
    SUM(v.BountyAmount) AS TotalBountyAmount,
    SUM(b.Class = 1) AS GoldBadges,
    SUM(b.Class = 2) AS SilverBadges,
    SUM(b.Class = 3) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.CreationDate
ORDER BY 
    u.Reputation DESC;

-- The above query groups user stats, counting posts, comments, votes, and badges,
-- allowing for performance assessment of complex joins on a large dataset.
