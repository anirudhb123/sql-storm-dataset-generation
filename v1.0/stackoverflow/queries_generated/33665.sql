WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId IN (1, 2)  -- Only Questions and Answers
),
PostActivity AS (
    SELECT p.Id AS PostId,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
           SUM(CASE WHEN v.VoteTypeId = 11 THEN 1 ELSE 0 END) AS UndeletionCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'  -- Posts from the last 30 days
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT ph.PostId,
           ph.CreationDate,
           ph.Comment AS CloseReason,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened posts
),
UserBadges AS (
    SELECT b.UserId,
           COUNT(b.Id) AS BadgeCount,
           MAX(b.Class) AS HighestBadgeClass  -- Highest class of badges (Gold=1, Silver=2, Bronze=3)
    FROM Badges b
    GROUP BY b.UserId
)
SELECT rp.PostId,
       rp.Title,
       pa.CommentCount,
       pa.UpVoteCount,
       pa.DownVoteCount,
       COALESCE(cp.CloseReason, 'N/A') AS LastCloseReason,
       ub.BadgeCount,
       ub.HighestBadgeClass,
       rp.Rank
FROM RankedPosts rp
LEFT JOIN PostActivity pa ON rp.PostId = pa.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseRank = 1  -- Most recent close reason
LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE rp.Rank <= 5  -- Top 5 posts per type
ORDER BY rp.PostTypeId, rp.Rank;
