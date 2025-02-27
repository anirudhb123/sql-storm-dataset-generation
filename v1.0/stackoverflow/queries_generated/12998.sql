-- Performance Benchmarking SQL Query

-- This query retrieves the number of posts per post type, average view count, and total score of posts grouped by post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(p.Score) AS TotalScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- This query calculates the number of votes per vote type, average score of posts that have votes, and total post count.
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount,
    AVG(p.Score) AS AveragePostScore,
    COUNT(DISTINCT p.Id) AS TotalPostsWithVotes
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

-- This query gathers performance metrics for user engagement including total views, upvotes, and downvotes per user.
SELECT 
    u.DisplayName,
    SUM(u.Views) AS TotalViews,
    SUM(u.UpVotes) AS TotalUpVotes,
    SUM(u.DownVotes) AS TotalDownVotes
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalViews DESC;

-- This query assesses the distribution of post history types based on their frequency.
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    HistoryCount DESC;
