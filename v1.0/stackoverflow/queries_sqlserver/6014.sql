
WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes, 
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.PostTypeId IN (1, 2) 
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
), UserPostStats AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           u.Reputation, 
           COUNT(DISTINCT rp.Id) AS PostCount, 
           SUM(rp.Upvotes) AS TotalUpvotes, 
           SUM(rp.Downvotes) AS TotalDownvotes
    FROM Users u
    JOIN RankedPosts rp ON rp.Id = u.Id
    WHERE rp.rn = 1 
    GROUP BY u.Id, u.DisplayName, u.Reputation
), UserBadges AS (
    SELECT UserId, 
           COUNT(*) AS GoldBadges, 
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges, 
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, 
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT u.DisplayName, 
       u.Reputation, 
       u.PostCount, 
       u.TotalUpvotes, 
       u.TotalDownvotes, 
       ub.GoldBadges, 
       ub.SilverBadges, 
       ub.BronzeBadges
FROM UserPostStats u
LEFT JOIN UserBadges ub ON u.UserId = ub.UserId
ORDER BY u.Reputation DESC, u.TotalUpvotes DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
