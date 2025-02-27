-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves statistics about posts, including the total number of posts,
-- number of questions, answers, and their average scores. It also joins several related tables
-- to gather insights on user contributions and tag usage.

SELECT 
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(CASE WHEN P.PostTypeId = 1 THEN P.Score END) AS AverageQuestionScore,
    AVG(CASE WHEN P.PostTypeId = 2 THEN P.Score END) AS AverageAnswerScore,
    COUNT(DISTINCT U.Id) AS TotalUsers,
    COUNT(DISTINCT T.Id) AS TotalTags,
    SUM(V.BountyAmount) AS TotalBountyAmount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')  -- Assuming Tags column is stored as a delimited string.
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Filter to the last year
GROUP BY 
    DATE(P.CreationDate)  -- Grouping by date to provide daily stats
ORDER BY 
    DATE(P.CreationDate) ASC;
