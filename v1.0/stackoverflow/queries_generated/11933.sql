-- Performance Benchmarking Query

-- This query will retrieve user statistics and post details to assess performance
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentsScore,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    MAX(v.CreationDate) AS LastVoteDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id
ORDER BY 
    u.Reputation DESC
LIMIT 100;  -- Limiting to top 100 users based on reputation for performance purposes
