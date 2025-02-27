WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.OwnerUserId,
           p.CreationDate,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpvoteCount,
           SUM(v.VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
UserStatistics AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           SUM(rp.PostRank) AS TotalPostRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(DISTINCT b.Id) > 5
)
SELECT us.UserId,
       us.DisplayName,
       us.Reputation,
       us.BadgeCount,
       COALESCE(MAX(rp.Score), 0) AS MaxPostScore,
       COALESCE(SUM(rp.CommentCount), 0) AS TotalComments,
       CASE WHEN AVG(rp.UpvoteCount) IS NULL THEN 0 ELSE AVG(rp.UpvoteCount) END AS AvgUpvotes,
       CASE WHEN AVG(rp.DownvoteCount) IS NULL THEN 0 ELSE AVG(rp.DownvoteCount) END AS AvgDownvotes
FROM UserStatistics us
LEFT JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId
GROUP BY us.UserId, us.DisplayName, us.Reputation, us.BadgeCount
ORDER BY us.Reputation DESC, MaxPostScore DESC
LIMIT 10;
