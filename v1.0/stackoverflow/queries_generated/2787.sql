WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
RecentPosts AS (
    SELECT p.OwnerUserId, p.Id AS PostId, p.Title, p.CreationDate, p.Score,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.OwnerUserId, p.Id, p.Title, p.CreationDate, p.Score
),
TopPosters AS (
    SELECT ur.Id AS UserId, ur.Reputation, COUNT(rp.PostId) AS PostCount,
           SUM(rp.Score) AS TotalScore
    FROM UserReputation ur
    LEFT JOIN RecentPosts rp ON ur.Id = rp.OwnerUserId
    GROUP BY ur.Id, ur.Reputation
    HAVING COUNT(rp.PostId) > 5
),
ClosedPosts AS (
    SELECT ph.PostId, ph.CreationDate, ph.Comment
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
)
SELECT up.Id AS UserId, up.Reputation, up.PostCount, 
       COALESCE(cp.ClosedCount, 0) AS ClosedPostCount,
       COALESCE(CAST(ROUND(AVG(rp.Score), 2) AS numeric), 0) AS AvgScore,
       STRING_AGG(DISTINCT CONCAT(rp.Title, ' (Score: ', rp.Score, ')'), '; ') AS RecentPosts
FROM TopPosters up
LEFT JOIN RecentPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN (
    SELECT OwnerUserId, COUNT(PostId) AS ClosedCount
    FROM ClosedPosts cp
    JOIN Posts p ON cp.PostId = p.Id
    GROUP BY OwnerUserId
) cp ON up.UserId = cp.OwnerUserId
GROUP BY up.Id, up.Reputation, up.PostCount
ORDER BY up.Reputation DESC, up.PostCount DESC
LIMIT 10;
