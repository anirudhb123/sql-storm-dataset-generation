-- Performance benchmarking query for Stack Overflow schema

-- Calculate the average response time for questions and total answers per question
SELECT 
    p.Id AS QuestionId,
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionCreationDate,
    COALESCE(AVG(a.CreationDate - p.CreationDate), INTERVAL '0 seconds') AS AverageResponseTime,
    COUNT(a.Id) AS TotalAnswers
FROM 
    Posts p
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
WHERE 
    p.PostTypeId = 1 -- Questions
GROUP BY 
    p.Id, p.Title, p.CreationDate
ORDER BY 
    AverageResponseTime DESC;

-- Benchmark the number of votes per type of post
SELECT 
    pt.Name AS PostType,
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    pt.Name, vt.Name
ORDER BY 
    VoteCount DESC;

-- Query to measure user activity by counting posts, votes, and comments
SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalVotes DESC, TotalComments DESC;

-- Benchmark the average score and views for questions based on tags
SELECT 
    t.TagName,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViews,
    COUNT(p.Id) AS TotalQuestions
FROM 
    Posts p
JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%' -- Assuming tags are comma-separated
WHERE 
    p.PostTypeId = 1 -- Questions
GROUP BY 
    t.TagName
ORDER BY 
    AverageScore DESC, AverageViews DESC;
