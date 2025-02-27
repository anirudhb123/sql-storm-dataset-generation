
WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate
    FROM Users
    WHERE Reputation > 1000
), PostStats AS (
    SELECT p.Id AS PostId, 
           p.OwnerUserId, 
           COUNT(c.Id) AS CommentCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           p.CreationDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate
), PopularPosts AS (
    SELECT ps.PostId, 
           ps.CommentCount, 
           ps.UpVotes, 
           ps.DownVotes, 
           ps.CreationDate,
           @row_number := IF(@current_user = ps.OwnerUserId, @row_number + 1, 1) AS Rank,
           @current_user := ps.OwnerUserId
    FROM PostStats ps, (SELECT @row_number := 0, @current_user := NULL) AS vars
    JOIN UserReputation ur ON ps.OwnerUserId = ur.Id
    ORDER BY ps.OwnerUserId, (ps.UpVotes - ps.DownVotes) DESC
), LatestPosts AS (
    SELECT PostId, CommentCount, UpVotes, DownVotes, CreationDate
    FROM PopularPosts
    WHERE Rank <= 5
)
SELECT lp.PostId, 
       p.Title, 
       p.Body, 
       lp.CommentCount, 
       lp.UpVotes, 
       lp.DownVotes, 
       u.DisplayName AS OwnerName
FROM LatestPosts lp
JOIN Posts p ON lp.PostId = p.Id
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
WHERE ph.PostHistoryTypeId IS NULL
ORDER BY lp.UpVotes DESC, lp.CommentCount DESC;
