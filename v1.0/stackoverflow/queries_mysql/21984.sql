
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        @row := IF(@prev = CASE WHEN u.Reputation > 1000 THEN 'High' 
                                      WHEN u.Reputation > 100 THEN 'Medium' 
                                      ELSE 'Low' END, @row + 1, 1) AS ReputationRank,
        @prev := CASE WHEN u.Reputation > 1000 THEN 'High' 
                      WHEN u.Reputation > 100 THEN 'Medium' 
                      ELSE 'Low' END 
    FROM Users u, (SELECT @row := 0, @prev := '') AS vars
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId,
        @postRank := @postRank + 1 AS PostRank 
    FROM Posts p, (SELECT @postRank := 0) AS vars
    WHERE p.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY p.CreationDate DESC
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount, 
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
),
VoteSummary AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
PostClosure AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId 
    GROUP BY p.Id
)
SELECT 
    r.UserId, 
    r.DisplayName, 
    r.Reputation, 
    r.ReputationRank, 
    COALESCE(b.BadgeCount, 0) AS BadgeCount, 
    COALESCE(b.HighestBadgeClass, 0) AS HighestBadgeClass, 
    rp.PostId, 
    rp.Title AS RecentPostTitle, 
    rp.CreationDate AS RecentPostDate, 
    ps.CloseCount AS TotalCloseCount, 
    ps.ReopenCount AS TotalReopenCount,
    COALESCE(vs.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(vs.TotalDownvotes, 0) AS TotalDownvotes
FROM RankedUsers r
LEFT JOIN UserBadges b ON r.UserId = b.UserId
LEFT JOIN RecentPosts rp ON rp.OwnerUserId = r.UserId
LEFT JOIN PostClosure ps ON rp.PostId = ps.PostId
LEFT JOIN VoteSummary vs ON rp.PostId = vs.PostId
WHERE r.ReputationRank <= 10
  AND (b.BadgeCount IS NULL OR b.BadgeCount > 0)
ORDER BY r.Reputation DESC, rp.CreationDate DESC
LIMIT 50;
