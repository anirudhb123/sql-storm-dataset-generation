WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopUsers AS (
    SELECT Id, DisplayName, Reputation
    FROM UserReputation
    WHERE ReputationRank <= 10
),
PostStatistics AS (
    SELECT p.Id AS PostId, p.Title, p.OwnerUserId, 
           COUNT(c.Id) AS CommentCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
DetailedPosts AS (
    SELECT ps.*, 
           COALESCE(u.DisplayName, 'Community User') AS OwnerName,
           CASE 
               WHEN ps.CommentCount > 10 THEN 'Highly Engaged'
               WHEN ps.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
               ELSE 'Low Engagement'
           END AS EngagementLevel
    FROM PostStatistics ps
    LEFT JOIN Users u ON ps.OwnerUserId = u.Id
)
SELECT dp.PostId, dp.Title, dp.OwnerName, 
       dp.CommentCount, dp.UpVoteCount, dp.DownVoteCount, 
       dp.EngagementLevel, u.Reputation
FROM DetailedPosts dp
JOIN TopUsers u ON dp.OwnerUserId = u.Id
WHERE dp.UserPostRank = 1
ORDER BY dp.UpVoteCount DESC, dp.CommentCount DESC 
LIMIT 5
UNION
SELECT NULL AS PostId, NULL AS Title, NULL AS OwnerName, 
       NULL AS CommentCount, NULL AS UpVoteCount, NULL AS DownVoteCount, 
       NULL AS EngagementLevel, AVG(Reputation) AS Reputation
FROM Users
WHERE Reputation IS NOT NULL
HAVING AVG(Reputation) > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL);
