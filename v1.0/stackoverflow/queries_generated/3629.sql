WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '1 YEAR'
    GROUP BY p.Id
), 
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.CommentCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM RankedPosts rp
    LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE rp.PostRank = 1
)
SELECT 
    tp.Title AS TopPostTitle,
    tp.Score,
    tp.CommentCount,
    COALESCE(tp.GoldBadges, 0) AS GoldBadges,
    COALESCE(tp.SilverBadges, 0) AS SilverBadges,
    COALESCE(tp.BronzeBadges, 0) AS BronzeBadges,
    (SELECT AVG(Score) FROM RankedPosts) AS AveragePostScore,
    (SELECT COUNT(*) FROM Posts p WHERE p.ViewCount > 1000) AS HighViewCountPosts
FROM TopPosts tp
ORDER BY tp.Score DESC
FETCH FIRST 10 ROWS ONLY;
