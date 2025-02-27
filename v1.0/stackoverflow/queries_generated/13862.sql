-- Performance Benchmarking Query
-- This query measures the number of posts, comments, and votes made by users,
-- along with their respective total scores and reputations.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes,
    SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
    SUM(COALESCE(u.Reputation, 0)) AS TotalReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId 
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalComments DESC;

-- The output of this query will provide insights into user engagement
-- on the platform by showing their contributions in terms of posts,
-- comments, and votes, along with their score totals and reputation.
