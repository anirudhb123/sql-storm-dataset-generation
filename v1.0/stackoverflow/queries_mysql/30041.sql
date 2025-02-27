
WITH RecursiveTopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, 
           @rank := @rank + 1 AS Rank
    FROM Users u, (SELECT @rank := 0) r
    WHERE u.Reputation > 1000
    ORDER BY u.Reputation DESC
),
PostStatistics AS (
    SELECT p.Id AS PostId, p.OwnerUserId, p.PostTypeId, 
           COUNT(v.Id) AS VoteCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
           MAX(p.CreationDate) AS LastActivityDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId
),
UserBadges AS (
    SELECT b.UserId, 
           GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') AS BadgesList,
           COUNT(b.Id) AS TotalBadges
    FROM Badges b
    GROUP BY b.UserId
),
ClosedPosts AS (
    SELECT ph.PostId, COUNT(*) AS ClosureCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    tu.DisplayName AS TopUser,
    ts.PostId,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = ts.PostId) AS CommentCount,
    ts.VoteCount,
    ts.UpvoteCount,
    ts.DownvoteCount,
    COALESCE(b.BadgesList, 'No Badges') AS Badges,
    COALESCE(cp.ClosureCount, 0) AS ClosureCount
FROM RecursiveTopUsers tu
INNER JOIN PostStatistics ts ON tu.Id = ts.OwnerUserId
LEFT JOIN UserBadges b ON tu.Id = b.UserId
LEFT JOIN ClosedPosts cp ON ts.PostId = cp.PostId
WHERE ts.PostTypeId = 1
AND ts.LastActivityDate >= CURDATE() - INTERVAL 30 DAY
ORDER BY ts.VoteCount DESC, tu.Reputation DESC
LIMIT 10;
