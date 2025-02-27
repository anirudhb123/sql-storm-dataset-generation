-- Performance benchmarking SQL query

-- 1. Query to count the number of posts grouped by PostType and generation time
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgTimeToActivity
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- 2. Query to analyze user activity based on the number of votes
SELECT 
    u.DisplayName, 
    COUNT(v.Id) AS TotalVotes, 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalVotes DESC;

-- 3. Query to examine post history changes over time
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(ph.Id) AS HistoryCount,
    MAX(ph.CreationDate) AS LastChanged
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id, p.Title
ORDER BY 
    LastChanged DESC;

-- 4. Query to measure average score of posts by type
SELECT 
    pt.Name AS PostType, 
    AVG(p.Score) AS AvgScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.Score IS NOT NULL
GROUP BY 
    pt.Name
ORDER BY 
    AvgScore DESC;

-- 5. Query to assess badge distribution across users
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalEarned,
    MIN(u.Reputation) AS MinReputation,
    AVG(u.Reputation) AS AvgReputation,
    MAX(u.Reputation) AS MaxReputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    TotalEarned DESC;
