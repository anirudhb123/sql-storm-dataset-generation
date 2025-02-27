WITH UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3 AS UpVotes, DownVotes) AS ScoreChange
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
),
CombinedRank AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.ScoreChange,
        ur.DisplayName,
        cr.ClosedPostId,
        cr.ClosedDate,
        cr.CloseReason
    FROM PostSummary ps
    JOIN UserRankings ur ON ps.OwnerUserId = ur.UserId
    LEFT JOIN ClosedPosts cr ON ps.PostId = cr.ClosedPostId
    WHERE ur.ReputationRank <= 100
)
SELECT 
    cr.PostId,
    cr.Title,
    cr.DisplayName AS Author,
    cr.CommentCount,
    cr.ScoreChange,
    COALESCE(cr.ClosedDate::date, 'No Closure') AS ClosedDate,
    COALESCE(cr.CloseReason, 'N/A') AS CloseReason
FROM CombinedRank cr
ORDER BY cr.ScoreChange DESC, cr.CommentCount DESC
LIMIT 50;
