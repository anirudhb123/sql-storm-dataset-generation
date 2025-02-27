-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the count of posts by each PostType and the average score for posts of each type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Additionally, we can measure the average number of comments per post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(COALESCE(c.CommentCount, 0)) AS AverageComments
FROM 
    Posts p
LEFT JOIN 
    (
        SELECT 
            PostId, 
            COUNT(Id) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageComments DESC;

-- Benchmarking the number of votes per post type as well
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(v.VoteTypeId IN (2)) AS TotalUpVotes,
    SUM(v.VoteTypeId IN (3)) AS TotalDownVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
