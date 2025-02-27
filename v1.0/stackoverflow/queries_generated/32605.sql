WITH RecursivePostHierarchy AS (
    SELECT Id, Title, ParentId, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
)

SELECT
    p.Id AS PostId,
    p.Title AS PostTitle,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    p.CreationDate AS PostCreationDate,
    COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
    CASE
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 
            (SELECT Title FROM Posts WHERE Id = p.AcceptedAnswerId)
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerTitle,
    STRING_AGG(t.TagName, ', ') AS Tags,
    ph.ActionCount,
    ph.UserCount,
    ph.ClosuredDate
FROM
    Posts p
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    (
        SELECT
            ph.PostId,
            COUNT(*) AS ActionCount,
            COUNT(DISTINCT ph.UserId) AS UserCount,
            MAX(ph.CreationDate) AS ClosuredDate
        FROM
            PostHistory ph
        WHERE
            ph.PostHistoryTypeId IN (10, 11)  -- considering closed and reopened
        GROUP BY
            ph.PostId
    ) ph ON p.Id = ph.PostId
LEFT JOIN
    (SELECT
        PostId,
        STRING_AGG(TagName, ', ') AS TagName
     FROM
         Tags t
     INNER JOIN
         PostTags pt ON pt.TagId = t.Id
     GROUP BY
         PostId) t ON p.Id = t.PostId
WHERE
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    AND p.Score > 5
    AND NOT EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = p.Id AND v.VoteTypeId = 3  -- Exclude downvoted posts
    )
GROUP BY
    p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName, p.AcceptedAnswerId, ph.ActionCount, ph.UserCount, ph.ClosuredDate
ORDER BY
    p.ViewCount DESC,
    p.Score DESC
LIMIT 100 OFFSET 0;

-- Bonus: Get total posts count by owner
SELECT
    Owner.DisplayName,
    COUNT(p.Id) AS TotalPosts
FROM
    Posts p
JOIN
    Users Owner ON p.OwnerUserId = Owner.Id
GROUP BY
    Owner.DisplayName
ORDER BY
    TotalPosts DESC
LIMIT 10;
