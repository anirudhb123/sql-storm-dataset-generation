WITH RecursivePostHistories AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.UserDisplayName,
        1 AS Level
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Only considering close/open events

    UNION ALL

    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.UserDisplayName,
        Level + 1
    FROM PostHistory ph
    INNER JOIN RecursivePostHistories rph ON rph.PostId = ph.PostId AND ph.CreationDate < rph.CreationDate
    WHERE rph.Level < 5 -- Limiting depth to 5
),

TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), '1970-01-01') AS LastClosedDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.PostTypeId = 1 -- We are only interested in questions
    GROUP BY p.Id, p.Title, p.ViewCount
),

Insights AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.UpVotes,
        tp.DownVotes,
        -- Ranking based on view count
        RANK() OVER (ORDER BY tp.ViewCount DESC) AS ViewRank,
        -- Adding insights based on closure history
        CASE 
            WHEN MAX(CASE WHEN rph.PostHistoryTypeId = 10 THEN 1 END) IS NOT NULL THEN 'Closed'
            WHEN MAX(CASE WHEN rph.PostHistoryTypeId = 11 THEN 1 END) IS NOT NULL THEN 'Reopened'
            ELSE 'Active'
        END AS Status,
        COUNT(rph.Id) AS ClosureCount
    FROM TopPosts tp
    LEFT JOIN RecursivePostHistories rph ON tp.PostId = rph.PostId
    GROUP BY tp.PostId, tp.Title, tp.ViewCount, tp.UpVotes, tp.DownVotes
)

SELECT 
    i.PostId,
    i.Title,
    i.ViewCount,
    i.UpVotes,
    i.DownVotes,
    i.ViewRank,
    i.Status,
    i.ClosureCount,
    COALESCE(DENSE_RANK() OVER (PARTITION BY i.Status ORDER BY i.ViewCount DESC), 0) AS StatusRank
FROM Insights i
WHERE i.ViewCount > 100 -- Only considering posts with significant views
ORDER BY i.ViewRank;
