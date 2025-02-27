WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.OwnerUserId, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
RecentPostHistory AS (
    SELECT ph.PostId, 
           ph.Comment, 
           ph.CreationDate AS HistoryDate, 
           p.Title AS PostTitle, 
           CASE 
               WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
               WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Deleted/Undeleted'
               ELSE 'Other' 
           END AS HistoryType
    FROM PostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
    WHERE ph.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '30 days')
),
UserReputation AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           u.Reputation, 
           COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    up.DisplayName AS PostOwner,
    ur.Reputation AS OwnerReputation,
    COALESCE(rph.Comment, 'No recent changes') AS RecentChangeComment,
    COALESCE(rph.HistoryType, 'No changes') AS ChangeType,
    ur.BadgeCount AS TotalBadges
FROM RankedPosts rp
LEFT JOIN RecentPostHistory rph ON rp.Id = rph.PostId
JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE rp.PostRank = 1 
  AND (ur.Reputation > 1000 OR ur.BadgeCount > 5)
ORDER BY rp.Score DESC, PostCreationDate DESC;
