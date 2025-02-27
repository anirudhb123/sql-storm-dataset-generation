WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rnk
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
UserBadges AS (
    SELECT u.Id AS UserId, b.Class, COUNT(*) AS BadgeCount
    FROM Users u
    JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, b.Class
),
UserStats AS (
    SELECT u.Id AS UserId, u.Reputation, u.DisplayName, 
           COALESCE(SUM(b.BadgeCount), 0) AS TotalBadges,
           COALESCE(SUM(CASE WHEN b.Class = 1 THEN b.BadgeCount ELSE 0 END), 0) AS GoldBadges,
           COALESCE(SUM(CASE WHEN b.Class = 2 THEN b.BadgeCount ELSE 0 END), 0) AS SilverBadges,
           COALESCE(SUM(CASE WHEN b.Class = 3 THEN b.BadgeCount ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN UserBadges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
)
SELECT up.DisplayName, up.Reputation, up.TotalBadges, up.GoldBadges, up.SilverBadges, up.BronzeBadges,
       rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount
FROM UserStats up
JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE rp.Rnk <= 5
ORDER BY up.Reputation DESC, rp.Score DESC
LIMIT 10;
