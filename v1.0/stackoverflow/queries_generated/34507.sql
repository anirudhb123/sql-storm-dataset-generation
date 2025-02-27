WITH RecursivePostHierarchy AS (
    -- CTE to build a hierarchy of posts and their accepted answers
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.AcceptedAnswerId,
        Level + 1
    FROM Posts a
    INNER JOIN RecursivePostHierarchy rp ON a.ParentId = rp.PostId
)

SELECT
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS Closures,
    AVG(DATEDIFF('minute', p.CreationDate, NOW())) AS AvgTimeToClose,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
LEFT JOIN Posts a ON a.ParentId = p.Id -- Answers
LEFT JOIN PostHistory ph ON ph.PostId = p.Id -- Post History
LEFT JOIN Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, '<>'))) -- Tag extraction
WHERE u.Reputation > 1000 -- Only experienced users
GROUP BY u.DisplayName
HAVING COUNT(DISTINCT p.Id) > 10 AND COUNT(DISTINCT a.Id) > 5 -- Must have more than 10 questions and 5 answers
ORDER BY AvgTimeToClose DESC
LIMIT 50;
