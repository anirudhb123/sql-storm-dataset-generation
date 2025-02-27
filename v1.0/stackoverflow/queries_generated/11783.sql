-- Performance Benchmarking SQL Query
-- This query will retrieve the count of posts along with the average score, 
-- average view count, and average comment count per post type. 
-- This should help in benchmarking the performance across different post types.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.CommentCount) AS AvgCommentCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
