WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotesCount,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentsCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
),
CombinedPostHistory AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastCloseReopenDate,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        JSON_AGG(ph.Comment) AS EditComments
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '2 years' 
    GROUP BY ph.PostId
),
PostMetrics AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.UpVotesCount,
        r.DownVotesCount,
        r.CommentsCount,
        c.FirstEditDate,
        c.LastCloseReopenDate,
        c.EditCount,
        c.EditComments
    FROM RankedPosts r
    LEFT JOIN CombinedPostHistory c ON r.PostId = c.PostId
)
SELECT 
    p.PostId,
    p.Title,
    COALESCE(E.FirstEditDate, 'No edits') AS FirstEditDate,
    COALESCE(E.LastCloseReopenDate, 'Never closed/reopened') AS LastCloseReopenDate,
    p.ViewCount,
    p.UpVotesCount,
    p.DownVotesCount,
    p.CommentsCount,
    CASE 
        WHEN p.UpVotesCount = 0 AND p.DownVotesCount = 0 THEN 'No votes yet'
        WHEN p.UpVotesCount > p.DownVotesCount THEN 'More upvotes than downvotes'
        WHEN p.UpVotesCount < p.DownVotesCount THEN 'More downvotes than upvotes'
        ELSE 'Equal votes'
    END AS VoteStatus,
    ARRAY(SELECT TagName FROM Tags t WHERE t.ExcerptPostId = p.PostId) AS Tags
FROM PostMetrics p
WHERE p.CommentsCount > 0
ORDER BY p.ViewCount DESC, p.Title
LIMIT 50;
