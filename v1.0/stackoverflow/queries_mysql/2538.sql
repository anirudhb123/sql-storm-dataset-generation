
WITH UserReputation AS (
    SELECT Id, Reputation, AccountId,
           FLOOR((ROW_NUMBER() OVER (ORDER BY Reputation DESC) - 1) / (SELECT COUNT(*) FROM Users) * 4) + 1 AS ReputationQuartile
    FROM Users
),
PostAnalytics AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.OwnerUserId,
           COUNT(c.Id) AS CommentCount, COUNT(DISTINCT v.UserId) AS UpVoteCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId 
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserPostData AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, ua.ReputationQuartile,
           pa.PostId, pa.Title, pa.PostRank, pa.CommentCount, 
           COALESCE(pa.UpVoteCount, 0) AS UpVotes, 
           COALESCE(pa.TotalDownVotes, 0) AS DownVotes
    FROM UserReputation ua
    LEFT JOIN PostAnalytics pa ON ua.Id = pa.OwnerUserId
    LEFT JOIN Users u ON u.Id = ua.Id
)
SELECT UserId, DisplayName, Reputation, ReputationQuartile,
       COUNT(PostId) AS TotalPosts, 
       SUM(UpVotes) AS TotalUpVotes,
       SUM(DownVotes) AS TotalDownVotes,
       GROUP_CONCAT(Title SEPARATOR '; ') AS PostTitles
FROM UserPostData
WHERE ReputationQuartile = 1
GROUP BY UserId, DisplayName, Reputation, ReputationQuartile
HAVING COUNT(PostId) > 5
ORDER BY TotalUpVotes DESC 
LIMIT 10;
