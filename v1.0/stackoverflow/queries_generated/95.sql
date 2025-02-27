WITH UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM Votes v
    GROUP BY v.UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id, p.Title
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ch.Name END) AS CloseReason
    FROM PostHistory ph
    JOIN CloseReasonTypes ch ON ph.Comment::int = ch.Id
    GROUP BY ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    COALESCE(cpr.CloseReason, 'Not Closed') AS CloseReason,
    (u.UpvoteCount - u.DownvoteCount) AS VoteBalance,
    CASE 
        WHEN (u.UpvoteCount - u.DownvoteCount) > 0 THEN 'Positive'
        WHEN (u.UpvoteCount - u.DownvoteCount) < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN ps.RecentRank <= 10 THEN 'Recent'
        ELSE 'Older'
    END AS PostRecency
FROM PostStats ps
LEFT JOIN UserVoteCounts u ON u.UserId = ps.UpvoteCount -- Get User Votes
LEFT JOIN ClosedPostReasons cpr ON ps.PostId = cpr.PostId
WHERE ps.CommentCount > 5
ORDER BY ps.CommentCount DESC, ps.UpvoteCount DESC;
