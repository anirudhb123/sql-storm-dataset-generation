
SELECT 
    COUNT(p.Id) AS TotalPostsLastYear,
    AVG(p.Score) AS AveragePostScore,
    SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotesReceived,
    YEAR(p.CreationDate) AS Year
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
GROUP BY 
    YEAR(p.CreationDate)
ORDER BY 
    Year DESC;
