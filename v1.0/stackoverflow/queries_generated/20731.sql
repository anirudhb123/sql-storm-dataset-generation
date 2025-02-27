WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation
),
RecentBadges AS (
    SELECT b.UserId, STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Date > NOW() - INTERVAL '1 year'
    GROUP BY b.UserId
),
PostHistoryDetails AS (
    SELECT ph.PostId, ph.PostHistoryTypeId, ph.UserId, ph.CreationDate, p.Title,
           CASE
               WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
               WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
               ELSE 'Other'
           END AS ActionTaken
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '30 days'
),
FilteredPosts AS (
    SELECT rp.Id AS PostId, rp.Title, rp.OwnerUserId, ub.Reputation, rsa.BadgeNames,
           phd.ActionTaken, CAST(phd.CreationDate AS DATE) AS RecentActionDate,
           COUNT(DISTINCT c.Id) AS CommentCount
    FROM RankedPosts rp
    JOIN UserReputation ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN RecentBadges rsa ON rp.OwnerUserId = rsa.UserId
    LEFT JOIN PostHistoryDetails phd ON rp.Id = phd.PostId
    LEFT JOIN Comments c ON rp.Id = c.PostId
    WHERE rp.PostRank = 1 
    GROUP BY rp.Id, rp.Title, rp.OwnerUserId, ub.Reputation, rsa.BadgeNames, phd.ActionTaken, phd.CreationDate
),
FinalMetrics AS (
    SELECT fp.PostId, fp.Title, fp.Reputation, COALESCE(fp.BadgeNames, 'None') AS BadgeNames,
           COALESCE(fp.CommentCount, 0) AS CommentCount,
           MAX(CASE WHEN fp.RecentActionDate IS NOT NULL THEN fp.ActionTaken END) AS LastAction,
           COUNT(DISTINCT CASE WHEN fp.RecentActionDate IS NOT NULL THEN fp.PostId END) AS ActionCount
    FROM FilteredPosts fp
    GROUP BY fp.PostId, fp.Title, fp.Reputation, fp.BadgeNames
)
SELECT f.PostId, f.Title, f.Reputation, f.BadgeNames,
       f.CommentCount, f.LastAction,
       CASE WHEN f.ActionCount > 1 THEN 'Frequent Actions' ELSE 'Infrequent Actions' END AS ActionFrequency,
       CASE 
           WHEN f.Reputation >= 1000 THEN 'Expert'
           WHEN f.Reputation BETWEEN 500 AND 999 THEN 'Intermediate'
           ELSE 'Novice'
       END AS UserStatus
FROM FinalMetrics f
ORDER BY f.Reputation DESC, f.CommentCount DESC;
