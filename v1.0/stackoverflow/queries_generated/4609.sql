WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER(PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM RankedPosts rp
    WHERE rp.rn = 1 AND rp.Score > 10
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId = 10 AND ph.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    COALESCE(cpd.CloseDate, 'Not Closed') AS CloseDate,
    COALESCE(cpd.CloseReason, 'N/A') AS CloseReason
FROM FilteredPosts fp
LEFT JOIN ClosedPostDetails cpd ON fp.PostId = cpd.PostId
ORDER BY fp.UpVotes DESC, fp.CreationDate DESC
LIMIT 50;
