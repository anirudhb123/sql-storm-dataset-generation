-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the count of posts, average score, and the total number of comments, 
-- along with user reputation for each user who has posted, assuming a sample of data across different categories.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    COUNT(c.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC;
