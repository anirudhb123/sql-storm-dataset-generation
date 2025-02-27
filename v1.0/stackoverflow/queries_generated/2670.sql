WITH UserReputation AS (
    SELECT Id, Reputation, LastAccessDate, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
    WHERE Reputation IS NOT NULL
),
RecentPosts AS (
    SELECT p.OwnerUserId, p.Id AS PostId, p.CreationDate, 
           COUNT(c.Id) AS CommentCount, SUM(v.VoteTypeId = 2) AS UpVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    WHERE p.CreationDate > NOW() - INTERVAL '1 month'
    GROUP BY p.OwnerUserId, p.Id, p.CreationDate
),
TopPostAuthors AS (
    SELECT ur.DisplayName, ur.Reputation, 
           COUNT(rp.PostId) AS TotalPosts, 
           SUM(rp.CommentCount) AS TotalComments,
           SUM(rp.UpVotes) AS TotalUpVotes
    FROM RecentPosts rp
    JOIN Users ur ON rp.OwnerUserId = ur.Id
    GROUP BY ur.DisplayName, ur.Reputation
),
CombinedData AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation,
           COALESCE(tpa.TotalPosts, 0) AS TotalPosts,
           COALESCE(tpa.TotalComments, 0) AS TotalComments,
           COALESCE(tpa.TotalUpVotes, 0) AS TotalUpVotes
    FROM Users u
    LEFT JOIN TopPostAuthors tpa ON u.DisplayName = tpa.DisplayName
)
SELECT cd.UserId, cd.DisplayName, cd.Reputation,
       cd.TotalPosts, cd.TotalComments, cd.TotalUpVotes,
       CASE 
           WHEN cd.Reputation > 1000 THEN 'High Reputation'
           WHEN cd.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
           ELSE 'Low Reputation'
       END AS ReputationCategory
FROM CombinedData cd
WHERE cd.Reputation IS NOT NULL
ORDER BY cd.Reputation DESC
LIMIT 10;

SELECT DISTINCT 
    COALESCE(php.UserId, b.UserId) AS UserId, 
    COALESCE(b.Name, 'No Badges') AS BadgesObtained
FROM Badges b
FULL OUTER JOIN (
    SELECT DISTINCT b.UserId
    FROM Badges b
    JOIN Posts p ON b.UserId = p.OwnerUserId
    WHERE p.CreationDate < NOW() - INTERVAL '1 year'
) php ON b.UserId = php.UserId
WHERE b.Date IS NOT NULL;
