-- Performance Benchmarking Query
-- This query retrieves statistics about posts, including the number of answers,
-- comments, votes, and the average score for each post type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COUNT(a.Id) AS TotalAnswers,
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
    SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Answers
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS CommentCount 
     FROM 
        Comments 
     GROUP BY 
        PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS VoteCount 
     FROM 
        Votes 
     GROUP BY 
        PostId) v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
