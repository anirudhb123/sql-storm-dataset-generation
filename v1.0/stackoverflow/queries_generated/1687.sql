WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 MONTH'
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, u.DisplayName,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM Users u 
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT u.UserId, u.DisplayName, u.Reputation, u.TotalBounty,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC, u.TotalBounty DESC) AS rn
    FROM UserReputation u
)
SELECT rp.Id AS PostId, rp.Title, rp.CreationDate, u.DisplayName AS Owner,
       rp.Score, rp.ViewCount, u.Reputation, u.TotalBounty
FROM RecentPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN TopUsers t ON u.Id = t.UserId
WHERE t.rn <= 10 -- Limit to top 10 users
AND rp.Score > 0 -- Only consider posts with a positive score
ORDER BY rp.CreationDate DESC, u.Reputation DESC;
