WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find all answers for each question
    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting point: Questions

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
)
SELECT
    q.PostId AS QuestionId,
    q.Title AS QuestionTitle,
    COALESCE(a.AnswerCount, 0) AS AnswerCount,
    AVG(COALESCE(r.Score, 0)) AS AverageAnswerScore,
    COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
    COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
    COUNT(DISTINCT ca.UserId) AS Commenters,
    MAX(q.CreationDate) AS LatestActivity
FROM Posts q
LEFT JOIN (
    SELECT
        ParentId,
        COUNT(Id) AS AnswerCount
    FROM Posts
    WHERE PostTypeId = 2  -- Answers
    GROUP BY ParentId
) a ON a.ParentId = q.PostId
LEFT JOIN RecursivePostHierarchy r ON r.ParentId = q.PostId
LEFT JOIN Badges b ON b.UserId = q.OwnerUserId
LEFT JOIN Votes v ON v.PostId = q.PostId
LEFT JOIN string_to_array(substring(q.Tags, 2, length(q.Tags) - 2), '><') AS tag_array ON true
LEFT JOIN Tags t ON t.TagName = tag_array
LEFT JOIN Comments ca ON ca.PostId = q.PostId
WHERE q.PostTypeId = 1  -- Only questions being considered
GROUP BY q.PostId, q.Title, a.AnswerCount
ORDER BY AverageAnswerScore DESC, AnswerCount DESC
LIMIT 10;
