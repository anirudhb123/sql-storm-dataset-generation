WITH UserReputation AS (
    SELECT Id, Reputation, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT p.Id AS PostId, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
           COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
           SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
),
PostDetail AS (
    SELECT ps.PostId, 
           ps.CommentCount, 
           ps.UpvoteCount, 
           ps.DownvoteCount, 
           u.Id AS UserId, 
           u.DisplayName,
           p.Title,
           COALESCE(ph.CloseCount, 0) AS CloseCount
    FROM PostStats ps
    JOIN Posts p ON ps.PostId = p.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostStats ps2 ON ps2.PostId = ps.PostId
    LEFT JOIN PostHistory ph ON ps.PostId = ph.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT ud.DisplayName, 
       pd.Title, 
       pd.CommentCount, 
       pd.UpvoteCount, 
       pd.DownvoteCount, 
       pd.CloseCount,
       ur.ReputationRank
FROM PostDetail pd
JOIN UserReputation ur ON pd.UserId = ur.Id
WHERE pd.CloseCount > 0
ORDER BY ur.ReputationRank, pd.CloseCount DESC
LIMIT 10
UNION ALL
SELECT 'Total', 
       NULL, 
       SUM(CommentCount), 
       SUM(UpvoteCount), 
       SUM(DownvoteCount), 
       SUM(CloseCount),
       NULL
FROM PostDetail;
