-- Performance Benchmarking Query

-- Retrieve the count of posts created per day along with their average score and average view count
SELECT 
    DATE(CreationDate) AS PostDate,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore,
    AVG(ViewCount) AS AverageViewCount
FROM 
    Posts
GROUP BY 
    DATE(CreationDate)
ORDER BY 
    PostDate;

-- Measure the number of votes per post type
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

-- Analyze the distribution of badges given to users
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalBadges
FROM 
    Badges b
GROUP BY 
    b.Name
ORDER BY 
    TotalBadges DESC;

-- Assess the average reputation of users who created posts
SELECT 
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId;

-- Evaluate the average time from post creation to acceptance of answers
SELECT 
    AVG(EXTRACT(EPOCH FROM (a.CreationDate - q.CreationDate)) / 3600) AS AverageHoursToAccept
FROM 
    Posts q
JOIN 
    Posts a ON q.Id = a.AcceptedAnswerId
WHERE 
    q.PostTypeId = 1 -- Questions
    AND a.PostTypeId = 2; -- Answers
