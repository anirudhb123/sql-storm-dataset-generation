WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
           COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
           COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentPostHistories AS (
    SELECT ph.PostId,
           ph.UserId,
           ph.CreationDate,
           ph.Comment,
           h.Name AS HistoryTypeName
    FROM PostHistory ph
    JOIN PostHistoryTypes h ON ph.PostHistoryTypeId = h.Id
    WHERE ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
),
UserStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS TotalPosts,
           SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
           AVG(p.Score) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)
SELECT rp.Title,
       rp.CreationDate,
       rp.Score,
       rp.ViewCount,
       rp.UpVotes,
       rp.DownVotes,
       u.DisplayName AS Author,
       us.TotalPosts,
       us.PositivePosts,
       us.AvgScore,
       COALESCE(rph.Comment, 'No recent history') AS RecentComment,
       COALESCE(rph.HistoryTypeName, 'No history') AS HistoryType
FROM RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN RecentPostHistories rph ON rp.Id = rph.PostId
JOIN UserStats us ON u.Id = us.UserId
WHERE rp.rn = 1
AND (rp.UpVotes - rp.DownVotes) > 10
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
