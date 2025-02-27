-- Performance Benchmarking Query

-- Fetch the total number of posts, average score, and total view count grouped by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Fetch user statistics including reputation, number of badges and posts created
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    COUNT(DISTINCT p.Id) AS TotalPostsCreated
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id
ORDER BY 
    u.Reputation DESC;

-- Measure the average comment count and average score on posts over time
SELECT 
    DATE_TRUNC('month', p.CreationDate) AS Month,
    AVG(p.CommentCount) AS AverageCommentCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    Month
ORDER BY 
    Month;

-- Retrieve the most upvoted and downvoted posts
SELECT 
    p.Title,
    p.Score,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id
ORDER BY 
    p.Score DESC
LIMIT 10;  -- Top 10 most upvoted posts

-- Get the total number of posts closed by reason type
SELECT 
    cht.Name AS CloseReason,
    COUNT(ph.Id) AS TotalClosedPosts
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    CloseReasonTypes cht ON ph.Comment::integer = cht.Id
WHERE 
    pht.Id = 10  -- Closed posts
GROUP BY 
    cht.Name
ORDER BY 
    TotalClosedPosts DESC;
