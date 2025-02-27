WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, u.DisplayName,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
)
SELECT u.DisplayName,
       u.Reputation,
       u.TotalBounties,
       p.Title,
       p.Score,
       p.CreationDate,
       CASE
           WHEN p.Score > 100 THEN 'High Score'
           WHEN p.Score IS NULL THEN 'No Score'
           ELSE 'Moderate Score'
       END AS ScoreCategory,
       (SELECT COUNT(DISTINCT c.Id)
        FROM Comments c
        WHERE c.PostId = p.Id) AS CommentCount
FROM Users u
JOIN UserReputation ur ON u.Id = ur.UserId
INNER JOIN RankedPosts p ON u.Id = p.OwnerUserId
WHERE ur.Reputation > 1000
  AND p.rn = 1
  AND EXISTS (SELECT 1
              FROM Votes v
              WHERE v.PostId = p.Id AND v.VoteTypeId = 2)
ORDER BY ur.Reputation DESC, p.CreationDate DESC
LIMIT 10;
