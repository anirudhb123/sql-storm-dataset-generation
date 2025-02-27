WITH RecursivePostHierarchy AS (
    SELECT p.Id, p.Title, p.ParentId, 0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL
    UNION ALL
    SELECT p.Id, p.Title, p.ParentId, r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
AggregatedVotes AS (
    SELECT v.PostId, 
           SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(v.Id) AS TotalVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
UserTopBadges AS (
    SELECT b.UserId, 
           COUNT(b.Id) AS BadgeCount,
           STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Date > CURRENT_TIMESTAMP - INTERVAL '1 YEAR'
    GROUP BY b.UserId
    HAVING COUNT(b.Id) > 1
),
PostDetails AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.ViewCount,
           COALESCE(av.UpVotes, 0) AS UpVotes,
           COALESCE(av.DownVotes, 0) AS DownVotes,
           COALESCE(ut.BadgeCount, 0) AS UserBadgeCount,
           COALESCE(ut.BadgeNames, 'No Badges') AS UserBadges
    FROM Posts p
    LEFT JOIN AggregatedVotes av ON p.Id = av.PostId
    LEFT JOIN UserTopBadges ut ON p.OwnerUserId = ut.UserId
)
SELECT r.Id, 
       r.Title AS PostTitle, 
       COUNT(c.Id) AS CommentCount, 
       pd.ViewCount, 
       pd.UpVotes,
       pd.DownVotes,
       pd.UserBadgeCount,
       pd.UserBadges
FROM RecursivePostHierarchy r
LEFT JOIN Comments c ON r.Id = c.PostId
LEFT JOIN PostDetails pd ON r.Id = pd.PostId
GROUP BY r.Id, r.Title, pd.ViewCount, pd.UpVotes, pd.DownVotes, pd.UserBadgeCount, pd.UserBadges
HAVING COUNT(c.Id) > 5
ORDER BY pd.ViewCount DESC, r.Title;

