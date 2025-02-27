-- Performance benchmarking SQL query to analyze data across various tables

-- This query retrieves the number of posts, users, and votes, as well as the average reputation of users
SELECT 
    (SELECT COUNT(*) FROM Posts) AS Total_Posts,
    (SELECT COUNT(*) FROM Users) AS Total_Users,
    (SELECT COUNT(*) FROM Votes) AS Total_Votes,
    AVG(Reputation) AS Average_User_Reputation 
FROM 
    Users;

-- Retrieve detailed statistics on post types and their average scores
SELECT 
    pt.Name AS Post_Type,
    COUNT(p.Id) AS Post_Count,
    AVG(p.Score) AS Average_Score,
    SUM(p.ViewCount) AS Total_Views
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    Post_Count DESC;

-- Analyze the distribution of badges earned by users
SELECT 
    b.Name AS Badge_Name,
    COUNT(b.Id) AS Badge_Count,
    AVG(u.Reputation) AS Average_User_Reputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    Badge_Count DESC;

-- Performance measurement of comments posted on the top 10 posts by vote count
SELECT 
    p.Title AS Post_Title,
    COUNT(c.Id) AS Comment_Count,
    SUM(c.Score) AS Total_Comment_Score
FROM 
    Posts p
LEFT JOIN 
    Comments c ON c.PostId = p.Id
WHERE 
    p.Id IN (SELECT Id FROM Posts ORDER BY Score DESC LIMIT 10)
GROUP BY 
    p.Title
ORDER BY 
    Comment_Count DESC;
