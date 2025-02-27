-- Performance Benchmarking SQL Query

-- Measure the total number of posts created, average score, and average view count by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Measure the number of users and their average reputation
SELECT 
    COUNT(u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
WHERE 
    u.CreationDate >= NOW() - INTERVAL '1 year';

-- Measure the total number of votes and average score by vote type
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes,
    AVG(p.Score) AS AveragePostScore
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;

-- Measure the number of comments and average comment score per post
SELECT 
    p.Id AS PostId,
    COUNT(c.Id) AS TotalComments,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id
ORDER BY 
    TotalComments DESC;

-- Measure response time by analyzing the time between post creation and accepted answer
SELECT 
    p.Id AS QuestionId,
    MAX(pa.CreationDate) AS AcceptedAnswerDate,
    p.CreationDate AS QuestionCreationDate,
    EXTRACT(EPOCH FROM (MAX(pa.CreationDate) - p.CreationDate)) AS ResponseTimeInSeconds
FROM 
    Posts p
LEFT JOIN 
    Posts pa ON p.Id = pa.AcceptedAnswerId
WHERE 
    p.PostTypeId = 1 -- Question
GROUP BY 
    p.Id
HAVING 
    MAX(pa.CreationDate) IS NOT NULL
ORDER BY 
    ResponseTimeInSeconds;
