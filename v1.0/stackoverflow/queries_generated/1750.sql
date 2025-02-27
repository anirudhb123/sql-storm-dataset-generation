WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) - COALESCE(SUM(v.VoteTypeId = 3), 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.Score,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC, ps.CommentCount DESC) AS PostRank
    FROM PostSummary ps
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.Score,
    cp.ClosedDate,
    cp.CloseReason
FROM UserVoteSummary ups
JOIN RankedPosts rp ON ups.UserId = rp.OwnerUserId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.Id
WHERE ups.VoteCount > 5 -- users with more than 5 votes
AND rp.PostRank <= 10 -- top 10 posts
ORDER BY ups.DisplayName, rp.Score DESC;
