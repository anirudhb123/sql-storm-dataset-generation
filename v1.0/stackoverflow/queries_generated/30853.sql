WITH RecursivePostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        COALESCE(ps.ParentId, 0) AS ParentId
    FROM
        Posts p
    LEFT JOIN Posts ps ON p.AcceptedAnswerId = ps.Id
    WHERE
        p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        COALESCE(ps.ParentId, 0) AS ParentId
    FROM
        Posts p
    INNER JOIN RecursivePostActivity r ON p.ParentId = r.PostId
),

UserScore AS (
    SELECT
        u.Id AS UserId,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
),

PostHistorySummary AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS Comments
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 11, 12, 13, 14, 15)  -- Close, Reopen, Delete, Undelete
    GROUP BY
        ph.PostId, ph.UserId, ph.PostHistoryTypeId
)

SELECT
    r.PostId,
    r.Title,
    r.CreationDate,
    r.LastActivityDate,
    r.Score,
    u.DisplayName AS Owner,
    COALESCE(us.TotalScore, 0) AS UserTotalScore,
    COALESCE(ps.ChangeCount, 0) AS HistoryChangeCount,
    COALESCE(ps.Comments, 'No comments') AS HistoryComments
FROM
    RecursivePostActivity r
JOIN
    Users u ON r.ParentId = u.Id
LEFT JOIN UserScore us ON u.Id = us.UserId
LEFT JOIN PostHistorySummary ps ON r.PostId = ps.PostId
WHERE
    r.LastActivityDate >= NOW() - INTERVAL '1 year'  -- Recent activity
ORDER BY
    r.Score DESC,
    r.LastActivityDate DESC
LIMIT 100;

This SQL query performs several operations for performance benchmarking including recursive common table expressions (CTEs) for retrieving hierarchical post activity and user scores, along with aggregating post history for summary information. It combines outer joins, correlated subqueries, complex predicates, and string aggregation, providing a rich dataset that showcases post dynamics and user interactions on the Stack Overflow platform.
