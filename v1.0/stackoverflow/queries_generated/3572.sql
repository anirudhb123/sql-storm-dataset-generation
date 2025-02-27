WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
UserScores AS (
    SELECT u.Id AS UserId, u.Reputation, COUNT(p.Id) AS TotalPosts,
           SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
           AVG(COALESCE((SELECT AVG(v.BountyAmount) 
                         FROM Votes v 
                         WHERE v.PostId = p.Id AND v.VoteTypeId IN (8, 9)), 0)) AS AvgBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
)
SELECT u.DisplayName, u.Reputation, us.TotalPosts, us.PositivePosts, us.AvgBounty, 
       rp.Title, rp.CreationDate, rp.Score
FROM UserScores us
JOIN Users u ON us.UserId = u.Id
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank = 1
WHERE us.Reputation > 1000
AND us.TotalPosts > 5
ORDER BY us.Reputation DESC, us.TotalPosts DESC
LIMIT 10

UNION ALL

SELECT u.DisplayName, u.Reputation, us.TotalPosts, us.PositivePosts, us.AvgBounty, 
       rp.Title, rp.CreationDate, rp.Score
FROM UserScores us
JOIN Users u ON us.UserId = u.Id
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank = 2
WHERE us.Reputation <= 1000
AND us.TotalPosts > 3
ORDER BY us.TotalPosts DESC
LIMIT 10;
