WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rnk,
           (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM Posts p
    WHERE p.PostTypeId = 1
      AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT u.Id AS UserId, 
           u.Reputation,
           (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
           (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) AS GoldBadges,
           (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 2) AS SilverBadges,
           (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 3) AS BronzeBadges
    FROM Users u
    WHERE u.Reputation > 1000
),
TopPosts AS (
    SELECT rp.*, 
           ur.Reputation,
           ur.PostCount,
           ur.GoldBadges,
           ur.SilverBadges,
           ur.BronzeBadges
    FROM RankedPosts rp
    LEFT JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE rp.rnk = 1
)
SELECT tp.Title, 
       tp.CreationDate, 
       tp.Score, 
       tp.ViewCount, 
       COALESCE(tp.Reputation, 0) AS UserReputation,
       COALESCE(tp.PostCount, 0) AS NumberOfPosts,
       (tp.GoldBadges + tp.SilverBadges + tp.BronzeBadges) AS TotalBadges
FROM TopPosts tp
WHERE tp.ViewCount > 100
ORDER BY tp.Score DESC, tp.ViewCount DESC
LIMIT 10
UNION ALL
SELECT 'Total Postsy & Badges' AS Title,
       NULL AS CreationDate,
       SUM(tp.Score) AS TotalScore,
       SUM(tp.ViewCount) AS TotalViewCount,
       NULL AS UserReputation,
       COUNT(tp.Id) AS TotalPosts,
       NULL AS TotalBadges
FROM TopPosts tp
WHERE tp.ViewCount > 100;
