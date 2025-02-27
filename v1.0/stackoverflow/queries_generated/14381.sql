-- Performance benchmarking query for StackOverflow schema

-- This query evaluates the performance by aggregating user reputation and counting posts, comments, and votes 
-- made by users within the last year, considering their contributions to both questions and answers.

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
    Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= NOW() - INTERVAL '1 year'
LEFT JOIN 
    Comments c ON u.Id = c.UserId AND c.CreationDate >= NOW() - INTERVAL '1 year'
LEFT JOIN 
    Votes v ON u.Id = v.UserId AND v.CreationDate >= NOW() - INTERVAL '1 year'
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= NOW() - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;
