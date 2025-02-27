-- Performance Benchmarking SQL Query

-- Retrieve the count of posts along with aggregate metrics grouped by PostType
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.AnswerCount) AS AverageAnswerCount,
    AVG(p.CommentCount) AS AverageCommentCount,
    AVG(p.FavoriteCount) AS AverageFavoriteCount,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Retrieve the average reputation of users who created posts
SELECT 
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId;

-- Retrieve most popular tags based on post usage
SELECT 
    t.TagName,
    COUNT(pt.Id) AS PostCount
FROM 
    Tags t
JOIN 
    Posts pt ON t.Id = ANY(string_to_array(pt.Tags, '><')::int[])
GROUP BY 
    t.TagName
ORDER BY 
    PostCount DESC
LIMIT 10;

-- Compute average votes per post, for analysis of post engagement
SELECT 
    p.Id AS PostId,
    COUNT(v.Id) AS TotalVotes,
    AVG(v.BountyAmount) AS AverageBounty
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id
ORDER BY 
    TotalVotes DESC;

-- Analyze badge distribution among users
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AvgUserReputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    BadgeCount DESC;

-- Timing execution for benchmarking performance
EXPLAIN ANALYZE
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.AnswerCount) AS AverageAnswerCount,
    AVG(p.CommentCount) AS AverageCommentCount,
    AVG(p.FavoriteCount) AS AverageFavoriteCount,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
