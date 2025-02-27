-- This query benchmarks the performance of retrieving detailed user activity, post stats, and badge information 
-- related to questions with a minimum score, including recursive CTEs, window functions, and multiple joins.

WITH RECURSIVE PostHierarchy AS (
    -- Base case: Get all the questions with a score greater than or equal to 10
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.OwnerUserId, 
        0 AS Depth
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.Score >= 10
    
    UNION ALL
    
    -- Recursive case: Join to find answers to those questions
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.OwnerUserId, 
        ph.Depth + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    u.Views,
    COUNT(DISTINCT p.PostId) AS QuestionCount,
    COUNT(DISTINCT a.PostId) AS AnswerCount,
    SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
    MAX(p.CreationDate) AS LatestPostDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT a.PostId) DESC) AS Ranking
FROM Users u
LEFT JOIN PostHierarchy ph ON u.Id = ph.OwnerUserId
LEFT JOIN Posts a ON a.ParentId = ph.PostId AND a.PostTypeId = 2
LEFT JOIN Badges b ON b.UserId = u.Id
LEFT JOIN Posts p ON p.Id = ph.PostId 
LEFT JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
WHERE u.Reputation > 100 AND u.Views IS NOT NULL
GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
ORDER BY Ranking
LIMIT 100;

-- References for NULL logic and edge cases
-- The query utilizes COALESCE to handle NULL values in badge classes.
-- The query ranks users based on the number of distinct answers related to their questions.
-- The query also incorporates potential tagging to gather relevant tags for each post.
