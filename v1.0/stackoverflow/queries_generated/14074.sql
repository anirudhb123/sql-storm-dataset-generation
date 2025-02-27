-- Performance Benchmarking Query

-- This query retrieves the average score and view count for questions in the Posts table,
-- as well as the number of answers and comments for each question.
-- It joins the Posts table with Votes and Comments to aggregate data effectively.

SELECT 
    p.Id AS QuestionId,
    p.Title,
    AVG(v.Score) AS AverageScore,
    p.ViewCount,
    COALESCE(a.AnswerCount, 0) AS AnswerCount,
    COALESCE(c.CommentCount, 0) AS CommentCount
FROM 
    Posts p
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS AnswerCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 2  -- Answer
    GROUP BY 
        PostId
) a ON p.Id = a.PostId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId 
WHERE 
    p.PostTypeId = 1  -- Question
GROUP BY 
    p.Id, p.Title, p.ViewCount, a.AnswerCount, c.CommentCount
ORDER BY 
    AverageScore DESC;
