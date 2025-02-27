-- Performance benchmarking query for the StackOverflow schema

-- This query retrieves the average score and view count of questions, 
-- the average number of answers and comments for each post type
-- along with the user information, benchmarking performance for various aggregates.

SELECT 
    p.PostTypeId,
    pt.Name AS PostTypeName,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(COALESCE(p.AnswerCount, 0)) AS AverageAnswerCount,
    AVG(COALESCE(C.CommentCount, 0)) AS AverageCommentCount,
    COUNT(DISTINCT u.Id) AS ActiveUserCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments C ON p.Id = C.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- considering posts from the last year
GROUP BY 
    p.PostTypeId, pt.Name
ORDER BY 
    p.PostTypeId;
