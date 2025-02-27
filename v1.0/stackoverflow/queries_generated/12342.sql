-- Performance benchmarking query to analyze the number of posts and their associated comments by post type
SELECT 
    pt.Name AS PostType,
    COUNT(DISTINCT p.Id) AS NumberOfPosts,
    COUNT(c.Id) AS NumberOfComments,
    AVG(COALESCE(COMMENT_COUNT, 0)) AS AvgCommentsPerPost
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
GROUP BY 
    pt.Name
ORDER BY 
    NumberOfPosts DESC;

