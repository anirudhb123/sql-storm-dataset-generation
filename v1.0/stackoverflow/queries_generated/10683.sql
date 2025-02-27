-- Performance benchmarking SQL query for Stack Overflow schema

-- This query calculates the average score of posts, the total number of comments,
-- and the average reputation of users who created posts. It involves multiple joins
-- and aggregations to assess performance.

SELECT 
    p.PostTypeId,
    AVG(p.Score) AS AvgPostScore,
    COUNT(c.Id) AS TotalComments,
    AVG(u.Reputation) AS AvgUserReputation
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY 
    p.PostTypeId
ORDER BY 
    p.PostTypeId;
