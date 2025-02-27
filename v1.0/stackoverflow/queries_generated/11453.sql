-- Performance benchmarking query to find the average score, view count, and answer count for questions
SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.AnswerCount) AS AvgAnswerCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.PostTypeId = 1 -- Only include questions
GROUP BY 
    pt.Name
ORDER BY 
    AvgScore DESC;
