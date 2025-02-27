-- Performance Benchmarking Query for Stack Overflow Schema

-- Fetching the count of posts per type along with metrics on views, scores, and user engagement.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalPostsByUsers,
    SUM(p.AnswerCount) AS TotalAnswers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Fetching user engagement metrics from the Users table
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    SUM(v.BountyAmount) AS TotalBounties
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC, Reputation DESC
LIMIT 10;

-- Analyzing the distribution of votes by vote type
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentVotes
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;
