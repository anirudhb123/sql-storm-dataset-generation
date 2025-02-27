WITH RECURSIVE UserReputationCTE AS (
    SELECT u.Id, u.DisplayName, u.Reputation,
           u.LastAccessDate,
           1 AS Level
    FROM Users u
    WHERE u.Reputation > 5000

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation,
           u.LastAccessDate,
           ur.Level + 1
    FROM Users u
    JOIN UserReputationCTE ur ON u.Id != ur.Id AND u.Reputation > ur.Reputation
),
RecentPostHistory AS (
    SELECT ph.PostId, ph.CreationDate, ph.UserId, ph.UserDisplayName, 
           P.Title, P.PostTypeId, 
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    JOIN Posts P ON ph.PostId = P.Id
    WHERE ph.CreationDate > NOW() - INTERVAL '30 days'
),
UserVoteCount AS (
    SELECT v.UserId, COUNT(*) AS TotalVotes
    FROM Votes v
    GROUP BY v.UserId
),
PostStatistics AS (
    SELECT p.Id AS PostId, 
           COUNT(DISTINCT c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
           MAX(ph.CreationDate) AS LastVoteDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN RecentPostHistory rph ON p.Id = rph.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '6 months'
    GROUP BY p.Id
)
SELECT u.Id AS UserId, 
       u.DisplayName, 
       u.Reputation,
       ur.Level,
       ps.PostId,
       ps.CommentCount,
       ps.UpVoteCount,
       ps.DownVoteCount,
       ps.LastVoteDate,
       ph.CreationDate AS LatestHistoryDate,
       ph.UserDisplayName AS LastEditor
FROM Users u
JOIN UserReputationCTE ur ON u.Id = ur.Id
LEFT JOIN PostStatistics ps ON ur.Id IN (SELECT OwnerUserId FROM Posts WHERE Score > 10)
LEFT JOIN RecentPostHistory ph ON ps.PostId = ph.PostId AND ph.rn = 1
WHERE u.Views > 1000
ORDER BY u.Reputation DESC, ps.CommentCount DESC;
