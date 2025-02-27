-- Performance benchmarking SQL query for the Stack Overflow schema

-- This query retrieves the count of posts, average scores, and total votes by post types, 
-- along with the number of comments. It aims to benchmark the performance of join operations 
-- and aggregate functions in the database.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(v.VoteTypeId = 2) AS TotalUpvotes,  -- Assuming VoteTypeId 2 is UpMod (upvote)
    SUM(v.VoteTypeId = 3) AS TotalDownvotes, -- Assuming VoteTypeId 3 is DownMod (downvote)
    COUNT(c.Id) AS TotalComments
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
