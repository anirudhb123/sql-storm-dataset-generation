-- Performance Benchmarking SQL Query

-- Measure the number of posts along with the average score and view count per post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Measure the number of comments and average score per user.
SELECT 
    u.DisplayName AS UserName,
    COUNT(c.Id) AS CommentCount,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Users u
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    CommentCount DESC;

-- Performance of post types by the number of votes
SELECT 
    pt.Name AS PostType,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
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
