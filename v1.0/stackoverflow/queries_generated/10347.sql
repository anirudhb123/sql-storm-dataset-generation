-- Performance Benchmarking Query to assess the distribution of posts by their types, 
-- along with the average score of the posts and the count of associated comments.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(c.CommentCount) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
