WITH UserReputation AS (
    SELECT Id, Reputation, LastAccessDate,
           CASE 
               WHEN Reputation < 1000 THEN 'Newbie'
               WHEN Reputation BETWEEN 1000 AND 10000 THEN 'Experienced'
               ELSE 'Veteran'
           END AS ReputationTier
    FROM Users
),
PostStats AS (
    SELECT p.Id AS PostId, p.OwnerUserId, p.CreationDate,
           COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
           COUNT(DISTINCT v.Id) AS VoteCount,
           MAX(COALESCE(p.ClosedDate, p.LastActivityDate)) AS LastActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > '2023-01-01'
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate
),
UserPostStats AS (
    SELECT u.DisplayName, u.Reputation, ur.ReputationTier, ps.PostId,
           ps.CommentCount, ps.VoteCount, ps.LastActivity
    FROM UserReputation ur
    JOIN PostStats ps ON ur.Id = ps.OwnerUserId
    JOIN Users u ON ur.Id = u.Id
),
TopPosts AS (
    SELECT *,
           RANK() OVER (PARTITION BY ReputationTier ORDER BY VoteCount DESC) AS VoteRank,
           RANK() OVER (PARTITION BY ReputationTier ORDER BY CommentCount DESC) AS CommentRank
    FROM UserPostStats
)
SELECT DisplayName, Reputation, ReputationTier, PostId, CommentCount, VoteCount, LastActivity
FROM TopPosts
WHERE VoteRank <= 5 OR CommentRank <= 5
ORDER BY ReputationTier, GREATEST(VoteCount, CommentCount) DESC;

-- Include some corner cases with NULL logic
SELECT p.Id, 
       p.Title,
       COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
       COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
       CASE WHEN p.OwnerUserId IS NULL THEN 'Community' 
            ELSE (SELECT DisplayName FROM Users u WHERE u.Id = p.OwnerUserId) 
       END AS OwnerName,
       (SELECT Text FROM Comments c WHERE c.PostId = p.Id ORDER BY CreationDate DESC LIMIT 1) AS LatestComment,
       CASE WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 6) THEN 'Closed'
            WHEN EXISTS (SELECT 1 FROM Posts p2 WHERE p2.AcceptedAnswerId = p.Id) THEN 'Answered'
            ELSE 'Unanswered'
       END AS Status
FROM Posts p
WHERE p.CreationDate BETWEEN '2023-01-01 00:00:00' AND NOW()
AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) > 0
ORDER BY LastActivity DESC
LIMIT 10;
