WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        COALESCE(NULLIF(rp.CommentCount, 0), 'No Comments') AS Comments,
        (UpVotes - DownVotes) AS NetVotes,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM RankedPosts rp
),

CloseReasons AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS CloseReason
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes cr ON ph.Comment = cr.Id::varchar
    GROUP BY ph.PostId
),

FinalMetrics AS (
    SELECT 
        pm.*,
        cr.CloseReason,
        CASE
            WHEN pm.NetVotes > 0 AND pm.Comments != 'No Comments' THEN 'Engaged'
            WHEN pm.NetVotes < 0 THEN 'Negative Feedback'
            ELSE 'Neutral'
        END AS EngagementLevel
    FROM PostMetrics pm
    LEFT JOIN CloseReasons cr ON pm.PostId = cr.PostId
)

SELECT 
    fm.PostId,
    fm.Title,
    fm.CreationDate,
    fm.ViewCount,
    fm.Comments,
    fm.NetVotes,
    fm.PostCategory,
    fm.CloseReason,
    fm.EngagementLevel
FROM FinalMetrics fm
WHERE fm.CloseReason IS NULL
ORDER BY fm.ViewCount DESC, fm.NetVotes DESC
LIMIT 100;

-- Determine the total upvotes and downvotes for all posts created in the last month
SELECT 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM Posts p
LEFT JOIN Votes v ON v.PostId = p.Id
WHERE p.CreationDate >= NOW() - INTERVAL '1 month';
