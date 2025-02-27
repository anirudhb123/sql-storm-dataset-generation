-- Performance benchmarking query to analyze the average number of votes per post type

SELECT 
    pt.Name AS PostTypeName,
    COUNT(v.Id) AS TotalVotes,
    AVG(COALESCE(vote_count, 0)) AS AvgVotesPerPost
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS vote_count 
     FROM Votes 
     GROUP BY PostId) v ON v.PostId = p.Id
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    pt.Name;
