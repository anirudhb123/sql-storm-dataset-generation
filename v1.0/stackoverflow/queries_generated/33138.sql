WITH RecursivePostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Select only top-level questions

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        r.Level + 1 AS Level
    FROM
        Posts p
    INNER JOIN
        RecursivePostHierarchy r ON p.ParentId = r.PostId
)

SELECT
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionCreationDate,
    p.Score AS QuestionScore,
    u.DisplayName AS UserDisplayName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotesCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotesCount,
    (
        SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM Tags t 
        WHERE t.Id IN (SELECT UNNEST(string_to_array(substr(p.Tags, 2, length(p.Tags) - 2), '><')::int[]))
    ) AS Tags,
    count(DISTINCT ph.PostId) AS AssociatedAnswerCount,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10) AS CloseCount
FROM
    Posts p
INNER JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    RecursivePostHierarchy ph ON p.Id = ph.ParentId
WHERE
    p.PostTypeId = 1  -- Only questions
GROUP BY
    p.Title, p.CreationDate, p.Score, u.DisplayName
ORDER BY
    p.Score DESC, p.CreationDate ASC
LIMIT 50 OFFSET 0;
