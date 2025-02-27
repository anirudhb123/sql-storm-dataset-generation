-- Performance Benchmarking SQL Query

-- This query retrieves the count of posts, average score, and total comment count grouped by PostType
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount
     FROM Comments
     GROUP BY PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Additional query to benchmark user reputation statistics
SELECT 
    u.Reputation,
    COUNT(*) AS UserCount,
    AVG(u.Views) AS AverageViews,
    SUM(u.UpVotes) AS TotalUpVotes,
    SUM(u.DownVotes) AS TotalDownVotes
FROM 
    Users u
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Executing these queries will provide insights into post performance and user engagement
