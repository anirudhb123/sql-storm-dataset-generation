-- Performance Benchmarking for StackOverflow Schema

-- 1. Count the total number of posts by type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- 2. Average Reputation of Users who own Posts
SELECT 
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId;

-- 3. Total Votes for each Post
SELECT 
    p.Title,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Title
ORDER BY 
    TotalVotes DESC;

-- 4. Distribution of badges by user reputation
SELECT 
    b.Class,
    COUNT(b.Id) AS BadgeCount
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Class
ORDER BY 
    BadgeCount DESC;

-- 5. Posts Closed by reason
SELECT 
    pht.Comment AS CloseReason,
    COUNT(ph.Id) AS CloseCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    pht.Id IN (10, 11) -- Closed and Reopened
GROUP BY 
    pht.Comment
ORDER BY 
    CloseCount DESC;

-- 6. Top 10 Tags by post count
SELECT 
    t.TagName,
    COUNT(pt.Id) AS PostCount
FROM 
    Tags t
JOIN 
    Posts pt ON t.Id = pt.Tags -- Assuming Tags column is joined for tag counting
GROUP BY 
    t.TagName
ORDER BY 
    PostCount DESC
LIMIT 10;

-- 7. Analyze edits over time
SELECT 
    ph.CreationDate, 
    COUNT(ph.Id) AS EditsCount
FROM 
    PostHistory ph
GROUP BY 
    ph.CreationDate
ORDER BY 
    ph.CreationDate;

-- 8. Average views of posts grouped by type
SELECT 
    pt.Name AS PostType,
    AVG(p.ViewCount) AS AvgViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AvgViews DESC;

-- 9. User activity over time
SELECT 
    DATE_TRUNC('month', u.CreationDate) AS Month,
    COUNT(u.Id) AS NewUsers
FROM 
    Users u
GROUP BY 
    Month
ORDER BY 
    Month;

-- 10. Recent comments on posts
SELECT 
    c.Text AS CommentText,
    p.Title AS PostTitle,
    c.CreationDate
FROM 
    Comments c
JOIN 
    Posts p ON c.PostId = p.Id
ORDER BY 
    c.CreationDate DESC
LIMIT 5;

