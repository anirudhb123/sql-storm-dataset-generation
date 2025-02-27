WITH UserVoteStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT
        p.Id AS ClosedPostId,
        ph.UserId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId = 10
)
SELECT
    ups.UserId,
    ups.DisplayName,
    pos.PostId,
    pos.Title,
    pos.Score,
    pos.ViewCount,
    pos.CommentCount,
    cp.CloseDate,
    cp.CloseReason,
    ups.UpvoteCount,
    ups.DownvoteCount,
    CASE
        WHEN ups.TotalVotes > 0 THEN (ups.UpvoteCount * 1.0 / ups.TotalVotes) * 100
        ELSE 0
    END AS UpvotePercentage,
    (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1 AND Score IS NOT NULL) AS AvgQuestionScore
FROM UserVoteStats ups
JOIN PostActivity pos ON ups.UserId = pos.OwnerUserId
LEFT JOIN ClosedPosts cp ON pos.PostId = cp.ClosedPostId
WHERE pos.RecentPostRank <= 5
ORDER BY pos.CreationDate DESC
LIMIT 100;
