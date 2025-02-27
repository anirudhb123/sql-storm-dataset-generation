-- Performance benchmarking for the Stack Overflow schema

-- 1. Query to retrieve the count of posts created per day along with average score
SELECT 
    DATE(CreationDate) AS PostCreationDate,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore
FROM 
    Posts
GROUP BY 
    DATE(CreationDate)
ORDER BY 
    PostCreationDate;

-- 2. Query to get the number of votes for each post type
SELECT 
    pt.Name AS PostType,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalVotes DESC;

-- 3. Query to find users with the highest reputation and their associated badges
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- 4. Query to analyze post history types and their frequency
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS TotalChanges
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    TotalChanges DESC;

-- 5. Query to track the number of comments made on posts over time
SELECT 
    DATE(CreationDate) AS CommentDate,
    COUNT(*) AS TotalComments
FROM 
    Comments
GROUP BY 
    DATE(CreationDate)
ORDER BY 
    CommentDate;

-- 6. Query to evaluate average view counts per tag
SELECT 
    t.TagName,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Tags t
JOIN 
    Posts p ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
GROUP BY 
    t.TagName
ORDER BY 
    AverageViewCount DESC;
