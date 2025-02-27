WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.ViewCount,
           p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
), 
UserBadges AS (
    SELECT u.Id AS UserId,
           COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), 
PostEngagement AS (
    SELECT p.Id AS PostId,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpvoteCount,
           SUM(v.VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
), 
ClosedPosts AS (
    SELECT p.Id AS PostId,
           MAX(ph.CreationDate) AS LastCloseDate,
           STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN CloseReasonTypes crt ON ph.Comment::INT = crt.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY p.Id
),
AggregateResults AS (
    SELECT p.PostId,
           p.Title,
           rp.Score,
           p.CommentCount,
           p.UpvoteCount,
           p.DownvoteCount,
           CASE 
               WHEN cp.LastCloseDate IS NOT NULL THEN 'Closed'
               ELSE 'Open'
           END AS PostStatus,
           cp.CloseReasons
    FROM PostEngagement p
    JOIN RankedPosts rp ON p.PostId = rp.PostId
    LEFT JOIN ClosedPosts cp ON p.PostId = cp.PostId
)
SELECT ag.PostId,
       ag.Title,
       ag.Score,
       ag.CommentCount,
       ag.UpvoteCount,
       ag.DownvoteCount,
       ag.PostStatus,
       COALESCE(ub.GoldBadges, 0) AS GoldBadges,
       COALESCE(ub.SilverBadges, 0) AS SilverBadges,
       COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
       CASE 
           WHEN ag.Score > 100 THEN 'Highly Engaged'
           WHEN ag.Score BETWEEN 50 AND 100 THEN 'Moderately Engaged'
           ELSE 'Low Engagement'
       END AS EngagementLevel
FROM AggregateResults ag
LEFT JOIN UserBadges ub ON ag.PostId = ub.UserId
WHERE ag.CommentCount > 0 OR ag.UpvoteCount > 0
ORDER BY ag.Score DESC, ag.CommentCount DESC
LIMIT 100;

-- This query aims to retrieve a list of posts from the last year, including user engagement metrics, badge statistics, and their closure status, with a focus on performance through various logical constructs, outer joins, and window functions while exploring semantical edge cases.
