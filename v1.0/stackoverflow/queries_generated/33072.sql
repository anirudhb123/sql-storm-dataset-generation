WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        1 AS Level
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12)  -- Close, Reopen, Delete
    UNION ALL
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        Level + 1
    FROM PostHistory ph
    INNER JOIN RecursivePostHistory rph ON ph.PostId = rph.PostId
    WHERE ph.CreationDate < rph.CreationDate
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosureDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Posts pd ON pd.Id = p.AcceptedAnswerId
    LEFT JOIN Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    WHERE p.PostTypeId = 1  -- Only considering questions
    GROUP BY p.Id
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.ViewCount,
        ps.Score,
        ps.AcceptedAnswer,
        ps.CommentCount,
        ps.VoteCount,
        ps.ClosureDate,
        ps.ReopenDate,
        ps.Tags,
        ROW_NUMBER() OVER (ORDER BY ps.ViewCount DESC, ps.Score DESC) AS Ranking
    FROM PostStatistics ps
    WHERE ps.ClosureDate IS NOT NULL AND ps.ReopenDate IS NOT NULL -- Only posts that were closed and reopened
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.AcceptedAnswer,
    fp.CommentCount,
    fp.VoteCount,
    fp.Tags,
    rph.Level,
    ROW_NUMBER() OVER (PARTITION BY fp.PostId ORDER BY rph.CreationDate DESC) AS PostHistoryRank
FROM FilteredPosts fp
LEFT JOIN RecursivePostHistory rph ON fp.PostId = rph.PostId
WHERE fp.Ranking <= 10 -- Top 10 posts based on view count and score
ORDER BY fp.ViewCount DESC, fp.Score DESC;
