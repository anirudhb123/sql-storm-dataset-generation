-- Performance Benchmarking Query for Posts and Users
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    u.LastAccessDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01'
ORDER BY 
    p.ViewCount DESC
LIMIT 100;

-- Aggregating past votes on posts
SELECT 
    p.Id AS PostId,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id;

-- Benchmark the number of edits made to posts over time
SELECT 
    ph.PostId,
    COUNT(*) AS EditCount,
    MIN(ph.CreationDate) AS FirstEdit,
    MAX(ph.CreationDate) AS LastEdit
FROM 
    PostHistory ph
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
GROUP BY 
    ph.PostId
ORDER BY 
    EditCount DESC
LIMIT 100;
