WITH UserReputation AS (
    SELECT Id, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT p.Id AS PostId, 
           p.PostTypeId,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS Upvotes, 
           SUM(v.VoteTypeId = 3) AS Downvotes,
           SUM(CASE WHEN v.VoteTypeId IN (6, 10) THEN 1 ELSE 0 END) AS CloseVotes,
           SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.PostTypeId
),
RecentPostHistory AS (
    SELECT ph.PostId, 
           ph.CreationDate,
           ph.PostHistoryTypeId,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevRank
    FROM PostHistory ph
    WHERE ph.CreationDate > (NOW() - INTERVAL '1 year')
),
PostCloseReasons AS (
    SELECT p.Id AS PostId, 
           COALESCE(r.Name, 'No Reason Given') AS CloseReason
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN CloseReasonTypes r ON ph.Comment::INT = r.Id
)
SELECT u.Id AS UserId, 
       u.DisplayName,
       COALESCE(ps.PostId, -1) AS TopPostId, 
       COALESCE(ps.CommentCount, 0) AS CommentCount,
       COALESCE(ps.Upvotes, 0) AS Upvotes,
       COALESCE(ps.Downvotes, 0) AS Downvotes,
       COALESCE(pr.CloseReason, 'N/A') AS CloseReason,
       u.Reputation,
       CASE 
           WHEN u.Reputation >= 1000 THEN 'High Reputation'
           WHEN u.Reputation >= 100 THEN 'Medium Reputation'
           ELSE 'Low Reputation' 
       END AS ReputationTier,
       CASE 
           WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) 
           THEN 'Gold Badge Holder' 
           ELSE 'No Gold Badges' 
       END AS BadgeStatus
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.Id
LEFT JOIN PostStats ps ON u.Id = (
    SELECT OwnerUserId FROM Posts 
    WHERE OwnerUserId = u.Id
    ORDER BY CreationDate DESC 
    LIMIT 1
)
LEFT JOIN PostCloseReasons pr ON ps.TopPostId = pr.PostId
WHERE u.CreationDate > (NOW() - INTERVAL '5 years')
      AND u.Location IS NOT NULL
      AND u.EmailHash IS NOT NULL
ORDER BY u.Reputation DESC, ur.ReputationRank
FETCH FIRST 100 ROWS ONLY;
