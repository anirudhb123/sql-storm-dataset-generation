-- Performance Benchmarking Query to assess the number of posts per user and their average score
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC, AverageScore DESC;

-- Performance Benchmarking Query to analyze votes distribution across post types
SELECT 
    pt.Name AS PostType,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    VoteTypes vt
JOIN 
    Votes v ON vt.Id = v.VoteTypeId
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    VoteCount DESC;

-- Performance Benchmarking Query to evaluate post editing activities
SELECT 
    ph.PostHistoryTypeId,
    COUNT(ph.Id) AS EditCount,
    MIN(ph.CreationDate) AS FirstEditDate,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    PostHistory ph
GROUP BY 
    ph.PostHistoryTypeId
ORDER BY 
    EditCount DESC;
