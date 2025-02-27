-- Performance benchmarking query

-- Get the number of posts by type along with average score and average view count
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Get the top 10 users by reputation along with their total posts and average scores of their posts
SELECT
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- Analyze the number of votes per post type
SELECT 
    vt.Name AS VoteTypeName,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN p.ViewCount IS NOT NULL THEN 1 ELSE 0 END) AS PostsWithViews
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    VoteCount DESC;

-- Track the frequency of post history types
SELECT 
    pht.Name AS PostHistoryTypeName,
    COUNT(ph.Id) AS HistoryCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    HistoryCount DESC;
