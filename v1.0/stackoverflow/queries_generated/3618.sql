WITH UserReputation AS (
    SELECT Id, Reputation, 
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostWithVotes AS (
    SELECT p.Id AS PostId, p.OwnerUserId, p.Title, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId, p.Title
),
ClosedPosts AS (
    SELECT ph.PostId, ph.CreationDate, 
           CREATETIME() AS CloseDuration,
           CASE 
               WHEN ph.Comment IS NULL THEN 'Unspecified'
               ELSE ph.Comment
           END AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
),
TopPostOwners AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, 
           COUNT(p.Id) AS NumberOfPosts,
           RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
)
SELECT u.DisplayName, 
       up.PostId, 
       up.Title, 
       up.UpVotes, 
       up.DownVotes, 
       CASE 
           WHEN cp.CloseDuration IS NOT NULL THEN 
               CONCAT('Closed ', EXTRACT(EPOCH FROM NOW() - cp.CreationDate) / 3600, ' hours ago due to: ', cp.CloseReason)
           ELSE 'Open'
       END AS Status,
       tr.UserId, tr.ReputationRank 
FROM PostWithVotes up
JOIN Users u ON up.OwnerUserId = u.Id
LEFT JOIN ClosedPosts cp ON up.PostId = cp.PostId
JOIN TopPostOwners tr ON u.Id = tr.UserId
WHERE tr.PostRank <= 10 AND up.UpVotes - up.DownVotes > 0
ORDER BY Status DESC, up.UpVotes DESC;

