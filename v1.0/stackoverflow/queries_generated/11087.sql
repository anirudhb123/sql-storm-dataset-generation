-- Performance Benchmarking Query on Stack Overflow Schema

-- Benchmark the number of Posts grouped by PostTypeId
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgResponseTimeSeconds,
    SUM(COALESCE(p.Score, 0)) AS TotalScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Benchmark the number of Votes received per User
SELECT 
    u.DisplayName,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalVotes DESC;

-- Benchmark the number of Comments made per Post
SELECT 
    p.Title,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    TotalComments DESC;

-- Benchmark active Users based on their Reputation and number of Posts
SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostsCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    u.Reputation DESC;

-- Benchmark Post History changes with number of revisions per Post
SELECT 
    p.Title,
    COUNT(ph.Id) AS RevisionCount
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Title
ORDER BY 
    RevisionCount DESC;
