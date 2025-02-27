-- Performance Benchmarking Query for the StackOverflow Schema

-- This query retrieves the count of posts per post type, average answers per question, 
-- and total votes for each post type, aggregating data from multiple tables.

SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(CASE WHEN p.PostTypeId = 1 THEN COALESCE(p.AnswerCount, 0) ELSE NULL END) AS AvgAnswersPerQuestion,
    SUM(v.VoteTypeId = 2 OR v.VoteTypeId = 3) AS TotalVotes  -- Assuming 2=upvote, 3=downvote
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN
    Votes v ON p.Id = v.PostId
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;
