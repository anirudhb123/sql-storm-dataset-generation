-- Performance Benchmarking Query

-- Retrieve the count of posts grouped by post type along with average views and scores for performance analysis
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AverageViews,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Retrieve the top users based on reputation and their post activity
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(v.BountyAmount) AS TotalBounties
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart votes
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- Calculate the average number of comments per post type
SELECT 
    pt.Name AS PostType,
    AVG(c.CommentCount) AS AverageComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    AverageComments DESC;

-- Evaluate post closure reasons with the count of posts affected
SELECT 
    cht.Name AS CloseReason,
    COUNT(ph.PostId) AS ClosedPostCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    CloseReasonTypes cht ON CAST(ph.Comment AS int) = cht.Id
WHERE 
    pht.Id IN (10, 11) -- Considering closed and reopened posts
GROUP BY 
    cht.Name
ORDER BY 
    ClosedPostCount DESC;
