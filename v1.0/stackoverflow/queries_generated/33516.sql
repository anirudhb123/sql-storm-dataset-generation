WITH RecursivePostHierarchy AS (
    -- This CTE will create a hierarchy of posts to find all answers for each question
    SELECT 
        Id AS PostId,
        Title,
        ParentId,
        CreationDate,
        1 AS Level
    FROM Posts 
    WHERE PostTypeId = 1 -- Starting from questions
    
    UNION ALL
    
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.ParentId,
        a.CreationDate,
        p.Level + 1 AS Level
    FROM Posts a
    INNER JOIN RecursivePostHierarchy p ON a.ParentId = p.PostId
)

SELECT 
    q.PostId AS QuestionId,
    q.Title AS QuestionTitle,
    q.CreationDate AS QuestionDate,
    COUNT(DISTINCT a.PostId) AS AnswerCount,
    AVG(u.Reputation) AS AvgReputation,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoted
FROM Posts q
LEFT JOIN RecursivePostHierarchy a ON q.Id = a.ParentId
LEFT JOIN Users u ON q.OwnerUserId = u.Id
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN STRING_TO_ARRAY(q.Tags, ',') AS t(TagName) ON (t.TagName IS NOT NULL)
LEFT JOIN Votes v ON q.Id = v.PostId
WHERE q.PostTypeId = 1 -- Filter for questions only
GROUP BY q.PostId, q.Title, q.CreationDate
HAVING COUNT(DISTINCT a.PostId) > 0 -- Only include questions with answers
ORDER BY q.CreationDate DESC;

-- Optional to benchmark performance across different scenarios
EXPLAIN ANALYZE 
SELECT 
    ...
This SQL query performs several complex tasks, including:

1. A recursive Common Table Expression (CTE) to establish the relationship between questions and their answers.
2. Multiple joins to gather extensive information about each question, such as the owner details, tag names, and badge counts.
3. Using aggregate functions like `COUNT`, `AVG`, and `SUM` to derive metrics from the underlying data.
4. Filtering to ensure only questions with answers are displayed.
5. An optional `EXPLAIN ANALYZE` for performance benchmarking, to check how efficiently the query runs.
