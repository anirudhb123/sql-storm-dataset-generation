WITH RecursivePostHistory AS (
    SELECT
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        1 AS Level
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Considering only Post Closed and Reopened for example purposes

    UNION ALL

    SELECT
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        Level + 1
    FROM PostHistory ph
    INNER JOIN RecursivePostHistory rph ON rph.PostId = ph.PostId
    WHERE ph.CreationDate < rph.CreationDate
)

SELECT
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS TotalCloseVotes,
    COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 11) AS TotalReopenVotes,
    CASE 
        WHEN MAX(ph.CreationDate) IS NULL THEN 'Never Closed'
        ELSE 'Most Recent Closed/Reopened: ' || TO_CHAR(MAX(ph.CreationDate), 'YYYY-MM-DD HH24:MI:SS')
    END AS LastCloseReopenDate,
    COALESCE(NULLIF(ROUND(SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8), 0), NULL), 0) AS TotalBounty
FROM Posts p
LEFT JOIN Comments c ON c.PostId = p.Id
LEFT JOIN RecursivePostHistory ph ON ph.PostId = p.Id
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Votes v ON v.PostId = p.Id
WHERE p.CreationDate >= '2022-01-01'
AND p.PostTypeId = 1 -- Only questions
GROUP BY p.Id, u.DisplayName
HAVING COUNT(DISTINCT c.Id) > 5 -- Only include questions with more than 5 comments
ORDER BY PostCreationDate DESC;
