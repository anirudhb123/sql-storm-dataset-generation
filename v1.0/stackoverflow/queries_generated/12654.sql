-- Performance Benchmarking Query

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter posts from the last year
)

SELECT 
    pt.Name AS PostType,
    COUNT(*) AS TotalPosts,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.Score) AS AvgScore,
    COUNT(CASE WHEN p.AnswerCount > 0 THEN 1 END) AS QuestionsWithAnswers,
    COUNT(CASE WHEN p.CommentCount > 0 THEN 1 END) AS QuestionsWithComments
FROM 
    RankedPosts p
JOIN 
    PostTypes pt ON p.PostId = p.PostId
WHERE 
    p.Rank <= 10 -- Only consider top 10 ranked posts per post type
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;
