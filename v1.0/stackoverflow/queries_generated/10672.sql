-- Performance benchmarking query for Stack Overflow schema

-- Measure the number of posts created in the last year, the average score of those posts, and the number of votes received

SELECT 
    COUNT(p.Id) AS TotalPostsLastYear,
    AVG(p.Score) AS AveragePostScore,
    SUM(v.Id IS NOT NULL) AS TotalVotesReceived
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE())
GROUP BY 
    YEAR(p.CreationDate)
ORDER BY 
    YEAR(p.CreationDate) DESC;
