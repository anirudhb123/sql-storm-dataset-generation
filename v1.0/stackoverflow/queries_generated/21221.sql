WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    JOIN Users U ON p.OwnerUserId = U.Id
    WHERE p.PostTypeId = 1 -- Considering only Questions
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN ph.CreationDate END) AS LastDeleted,
        MAX(CASE WHEN ph.PostHistoryTypeId = 5 THEN ph.CreationDate END) AS LastBodyEdit
    FROM PostHistory ph
    GROUP BY ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Reputation,
        COALESCE(ph.LastClosed, 'Never') AS LastClosed,
        COALESCE(ph.LastDeleted, 'Never') AS LastDeleted,
        COALESCE(ph.LastBodyEdit, 'Never') AS LastBodyEdit,
        rp.CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM RankedPosts rp
    LEFT JOIN PostHistoryDetails ph ON rp.PostId = ph.PostId
    LEFT JOIN Votes v ON rp.PostId = v.PostId
    GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.Reputation, ph.LastClosed, ph.LastDeleted, ph.LastBodyEdit, rp.CommentCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.Reputation,
    ps.CommentCount,
    ps.LastClosed,
    ps.LastDeleted,
    ps.LastBodyEdit,
    CASE 
        WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'Positive'
        WHEN ps.UpVoteCount < ps.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN ps.Reputation IS NULL THEN 'Anonymous User'
        ELSE ps.Reputation::TEXT || ' Reputation'
    END AS UserReputation,
    CONCAT('Post (ID: ', ps.PostId, ') has ', ps.CommentCount, ' comments and ', ps.UpVoteCount, ' upvotes!') AS CommentSummary
FROM PostStatistics ps
WHERE ps.ViewCount > 100
ORDER BY ps.ViewCount DESC, ps.Score DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
