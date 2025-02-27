-- Performance benchmarking query for Stack Overflow schema

-- Retrieve the count of posts, average score, and total view count by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Retrieve the most active users based on their contributions
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(p.Score) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC;

-- Retrieve the number of votes by vote type and their impact on post score
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN vt.Id IN (2, 3) THEN 1 ELSE 0 END) AS ImpactOnScore
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;

-- Execute a query to check the average time to answer questions
SELECT 
    AVG(EXTRACT(EPOCH FROM (a.CreationDate - q.CreationDate))/3600) AS AverageHoursToAnswer
FROM 
    Posts q
JOIN 
    Posts a ON q.Id = a.ParentId
WHERE 
    q.PostTypeId = 1 AND a.PostTypeId = 2;

-- Retrieve the distribution of closed posts by reason
SELECT 
    crt.Name AS CloseReason,
    COUNT(ph.Id) AS TotalClosedPosts
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id
WHERE 
    pht.Id = 10  -- Post Closed
GROUP BY 
    crt.Name
ORDER BY 
    TotalClosedPosts DESC;
