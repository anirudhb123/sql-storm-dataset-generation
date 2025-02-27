-- Performance benchmarking query for StackOverflow schema

-- Measure the total number of posts, their average score, and total view count grouped by post type
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

-- Measure user engagement by calculating the total number of votes per user along with their reputation
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(v.Id) AS TotalVotes
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalVotes DESC;

-- Check the distribution of badges by class
SELECT 
    b.Class,
    COUNT(b.Id) AS TotalBadges
FROM 
    Badges b
GROUP BY 
    b.Class
ORDER BY 
    b.Class;

-- Analyze the performance of accepted answers by measuring their scores and view counts
SELECT 
    COUNT(p.Id) AS TotalAcceptedAnswers,
    AVG(p.Score) AS AvgAcceptedAnswerScore,
    SUM(p.ViewCount) AS TotalAcceptedAnswersViewCount
FROM 
    Posts p
WHERE 
    p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL;

-- Determine the most active users based on the number of posts and comments they contributed
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    COUNT(c.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts + TotalComments DESC;
