-- Performance Benchmarking SQL Query

-- Benchmarking the number of posts, their types, and the number of associated votes and comments

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Explanation:
-- This query retrieves benchmarks related to post types, including:
-- 1. Total number of posts for each post type (e.g., Question, Answer).
-- 2. Total upvotes and downvotes associated with those posts.
-- 3. Total number of comments associated with each post type.
-- The results will be grouped by the post type and ordered by the total number of posts in descending order.
