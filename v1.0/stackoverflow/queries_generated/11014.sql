-- Performance Benchmarking Query for StackOverflow Schema

-- Measure the average number of votes per post and the total number of posts grouped by PostTypeId
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(voteCount) AS AvgVotesPerPost
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(Id) AS voteCount
     FROM Votes
     GROUP BY PostId) v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Measure the average reputation of users who created posts
SELECT 
    AVG(u.Reputation) AS AvgUserReputation,
    COUNT(DISTINCT p.OwnerUserId) AS UniquePostOwners
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.OwnerUserId != -1;  -- Exclude community user posts

-- Benchmark the total number of posts created in the last month
SELECT 
    COUNT(*) AS TotalPostsLastMonth
FROM 
    Posts
WHERE 
    CreationDate >= NOW() - INTERVAL '1 month';

-- Measure the total number of comments for posts of type 'Question'
SELECT 
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1;  -- Only questions

-- Measure the distribution of post's view counts
SELECT 
    COUNT(*) AS Count,
    CASE 
        WHEN ViewCount < 10 THEN 'Less than 10'
        WHEN ViewCount < 100 THEN '10 to 99'
        WHEN ViewCount < 1000 THEN '100 to 999'
        ELSE '1000 and above'
    END AS ViewCountRange
FROM 
    Posts
GROUP BY 
    ViewCountRange
ORDER BY 
    ViewCountRange;
