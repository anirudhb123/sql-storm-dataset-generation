-- Performance Benchmarking Query

-- Benchmarking the average score and view count of posts by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Benchmarking the number of votes by vote type
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes,
    AVG(v.BountyAmount) AS AverageBounty
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;

-- Benchmarking users by reputation and total post count
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    u.Reputation DESC;

-- Benchmarking the closure reasons for posts
SELECT 
    cr.Name AS CloseReason,
    COUNT(ph.Id) AS TotalClosures
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    CloseReasonTypes cr ON ph.Comment::int = cr.Id
WHERE 
    pht.Name = 'Post Closed'
GROUP BY 
    cr.Name
ORDER BY 
    TotalClosures DESC;
