WITH RecursiveCTE AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        CAST(NULL AS VARCHAR(50)) AS ParentPostTitle,
        0 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT
        a.Id,
        a.Title,
        a.Score,
        a.CreationDate,
        q.Title,
        Level + 1
    FROM
        Posts a
    INNER JOIN
        Posts q ON a.ParentId = q.Id
    WHERE
        q.PostTypeId = 1  -- Questions
)

SELECT
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    SUM(p.Score) AS TotalScore,
    COALESCE(MAX(b.Class), 0) AS HighestBadgeClass,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(v.VoteTypeId) DESC) AS UserRank
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])  -- Tags in array
LEFT JOIN
    Comments c ON c.PostId = p.Id
LEFT JOIN
    Badges b ON b.UserId = u.Id
LEFT JOIN
    Votes v ON v.PostId = p.Id
GROUP BY
    u.Id
HAVING
    COUNT(DISTINCT p.Id) > 0
ORDER BY
    TotalScore DESC;

-- Additional analysis on Posts with no accepted answers
SELECT
    p.Id,
    p.Title,
    p.ViewCount,
    p.Score,
    'No Accepted Answer' AS Status
FROM
    Posts p
LEFT OUTER JOIN
    Posts a ON p.AcceptedAnswerId = a.Id
WHERE
    p.PostTypeId = 1  -- Questions
    AND a.Id IS NULL  -- No accepted answer
ORDER BY
    p.CreationDate DESC
LIMIT 10;

-- Final summary
SELECT
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HotQuestions,
    COUNT(DISTINCT u.Id) AS TotalUsers
FROM
    Posts p
INNER JOIN
    Users u ON p.OwnerUserId = u.Id
WHERE
    p.PostTypeId = 1; -- Questions

