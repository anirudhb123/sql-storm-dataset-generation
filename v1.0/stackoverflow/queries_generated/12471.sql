-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the count of posts, their average score, and aggregates the number of votes by type
-- It joins multiple tables to gather comprehensive insights into post performance across different categories

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AvgScore,
    SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    SUM(CASE WHEN vt.VoteTypeId = 10 THEN 1 ELSE 0 END) AS TotalCloseVotes,
    SUM(CASE WHEN vt.VoteTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopenVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes vt ON p.Id = vt.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Adjust this to your benchmarking period
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
