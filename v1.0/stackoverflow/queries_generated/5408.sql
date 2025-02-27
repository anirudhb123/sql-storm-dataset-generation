WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, LastAccessDate,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
    WHERE Reputation > 1000
),
TopPosts AS (
    SELECT p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId, 
           u.DisplayName as OwnerDisplayName, 
           COUNT(c.Id) AS CommentCount,
           COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.Score > 10 AND p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),
UserBadges AS (
    SELECT b.UserId, 
           COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT ur.DisplayName, ur.Reputation, ur.LastAccessDate, 
       tp.Title, tp.Score, tp.CommentCount, tp.VoteCount, 
       ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
FROM UserReputation ur
JOIN TopPosts tp ON ur.Id = tp.OwnerUserId
LEFT JOIN UserBadges ub ON ur.Id = ub.UserId
WHERE ur.Rank <= 10 
ORDER BY ur.Reputation DESC, tp.Score DESC;
