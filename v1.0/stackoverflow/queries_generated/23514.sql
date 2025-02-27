WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           u.DisplayName AS OwnerDisplayName,
           RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
      AND p.Score IS NOT NULL
),
FilteredPostHistory AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           ph.UserDisplayName,
           ph.CreationDate AS HistoryDate,
           ph.Comment,
           ph.Text AS HistoricalText
    FROM PostHistory ph
    WHERE ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
      AND ph.PostHistoryTypeId IN (10, 11, 12, 19) -- Closed, Reopened, Deleted, and Protected
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
PostVoteSummary AS (
    SELECT p.Id AS PostId,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT rp.PostId,
       rp.Title,
       rp.CreationDate,
       rp.Score,
       rp.ViewCount,
       rp.OwnerDisplayName,
       COALESCE(ps.UpVotes, 0) AS UpVotes,
       COALESCE(ps.DownVotes, 0) AS DownVotes,
       COUNT(DISTINCT ph.UserDisplayName) AS HistoryActions,
       ub.BadgeCount AS UserBadges,
       ub.GoldBadges,
       ub.SilverBadges,
       ub.BronzeBadges 
FROM RankedPosts rp
LEFT JOIN PostVoteSummary ps ON rp.PostId = ps.PostId
LEFT JOIN FilteredPostHistory ph ON rp.PostId = ph.PostId
LEFT JOIN UserBadges ub ON ub.UserId = rp.OwnerDisplayName
WHERE rp.ScoreRank <= 10 
GROUP BY rp.PostId, 
         rp.Title, 
         rp.CreationDate, 
         rp.Score, 
         rp.ViewCount, 
         rp.OwnerDisplayName, 
         ub.BadgeCount, 
         ub.GoldBadges, 
         ub.SilverBadges, 
         ub.BronzeBadges 
ORDER BY rp.ViewCount DESC, 
         rp.Score DESC
LIMIT 50;
This query combines several complex constructs, including CTEs for ranking posts, filtering post history, summarizing user badges, and aggregating vote types while using a variety of joins. It also employs window functions for ranking, and handles various NULL semantics and grouping to provide a comprehensive view of the top posts within the last year.
